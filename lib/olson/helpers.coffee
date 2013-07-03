
# A shim for IE8+9 Array.indexOf
Array::indexOf or= (item) ->
    for x, i in this
        return i if x is item
    return -1

# Some helpers for going between day names and indices.
Days =
    DayShortNames: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    DayIndex: (name) ->
        @DayShortNames.indexOf name
    DayNameFromIndex: (dayIdx) ->
        @DayShortNames[dayIdx]
    AddToDate: (dt, days) ->
        Time.MakeDateFromTimeStamp (dt.getTime() + (days * Milliseconds.inDay))

# Some helpers for going between month names and indices
Months =
    MonthsShortNames: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    CompareRuleMatch: new RegExp "([a-zA-Z]*)([\\<\\>]?=)([0-9]*)"
    MonthIndex: (shortName) ->
        @MonthsShortNames.indexOf shortName.slice(0, 3)
    IsDayOfMonthRule: (str) ->
        str.indexOf(">") > -1 or str.indexOf("<") > -1 or str.indexOf("=") > -1
    IsLastDayOfMonthRule: (str) ->
        str[0..3] == "last"
    DayOfMonthByRule: (str, year, month) ->
        # Parse our onStr into the components
        ruleParse = @CompareRuleMatch.exec str

        if !ruleParse
            throw new Error "Unable to parse the 'on' rule for #{str}"

        # Whoa, destructured assignment? Hell yeah!
        [dayName, testPart, dateIndex] = ruleParse[1..3]

        dateIndex = parseInt dateIndex, 10
        if dateIndex is NaN
            throw new Error "Unable to parse the dateIndex of the 'on' rule for #{str}"
        
        dayIndex = helpers.Days.DayIndex dayName

        # Set up the compare functions based on the conditional parsed from the onStr
        compares =
            ">=": (a, b) -> a >= b
            "<=": (a, b) -> a <= b
            ">": (a, b) -> a > b
            "<": (a, b) -> a < b
            "=": (a, b) -> a == b

        compareFunc = compares[testPart]
        if !compareFunc
            throw new Error "Unable to parse the conditional for #{testPart}"

        # Begin at the beginning of the month, at worst we are iterating 30 or so extra times.
        testDate = helpers.Time.MakeDateFromParts year, month

        # Go forward one day at a time until we get a matching day of the week (Sun) and the compare of the date of the month passes (8 >= 8)
        while !(dayIndex == testDate.getUTCDay() and compareFunc(testDate.getUTCDate(), dateIndex))
            testDate = helpers.Days.AddToDate testDate, 1

        testDate.getUTCDate()
    LastDayOfMonthRule: (str, year, month) ->
        # Get the last day with a matching name
        dayName = str[4..]
        # TODO: Always has a capital first letter?
        dayIndex = helpers.Days.DayIndex dayName

        # To get the last day of the month we set the date to the first day of next month, and move back one day.
        
        # Set the date to the first day of the next month
        if month < 11
            lastDay = helpers.Time.MakeDateFromParts year, (month + 1)
        else
            # Account for going over to the next year.
            lastDay = helpers.Time.MakeDateFromParts year + 1, 0

        # Move back one day to the last day of the current month.
        lastDay = helpers.Days.AddToDate lastDay, -1

        # Iterate backward until our dayIndex matches the last days index
        while lastDay.getUTCDay() != dayIndex
            lastDay = helpers.Days.AddToDate lastDay, -1
        
        return lastDay.getUTCDate()

Milliseconds =
    inDay:    86400000
    inHour:   3600000
    inMinute: 60000
    inSecond: 1000

# Some helpers for dealing with time values
Time =
    Add: (dt, hours = 0, mins = 0, secs = 0) ->
        newTs = dt.getTime() + (hours * Milliseconds.inHour) + (mins * Milliseconds.inMinute) + (secs * Milliseconds.inSecond)
        @MakeDateFromTimeStamp newTs

    # Slightly different cases for GMT Strings, so we have them separated out
    # *NOTE*: Seconds will be NaN if they are not present
    ParseGMTOffset: (str) ->
        reg = new RegExp("(-)?([0-9]*):([0-9]*):?([0-9]*)?")
        matches = reg.exec str
        
        result = if matches then (parseInt match, 10 for match in matches[2..]) else [0,0,0]

        # Inject in whether we are negative
        isNeg = matches && matches[1] == "-"
        result.splice 0, 0, isNeg

        result

    # Parse a time string, usually in the form "2:00".  A 24-hour time string.
    ParseTime: (str) ->
        reg = new RegExp("(\\d*)\\:(\\d*)([wsugz]?)")
        matches = reg.exec str

        return [0, 0, ''] unless matches

        timeParts = (parseInt match, 10 for match in matches[1..2])

        # Append on the qualifier at the end
        qual = if matches[3] then matches[3] else ''
        timeParts.push qual

        # return the parts
        timeParts

    # Applies a GMT Style Offset.  -5:50:36 would return a new time that is 5 hours, 50 minutes and 36 seconds ahead of the passed in one
    # This is used to reconcile a standard time to UTC, however, if reverse is passed we can convert from UTC to Standard
    ApplyOffset: (dt, offset, reverse) ->
        offset_ms = (Milliseconds.inHour * offset.hours) + (Milliseconds.inMinute * offset.mins) + (Milliseconds.inSecond * offset.secs)

        offset_ms = offset_ms * -1 if !offset.negative

        if reverse
            offset_ms = offset_ms * -1

        @MakeDateFromTimeStamp(dt.getTime() + offset_ms)

    # Applies a SAVE value by adjusting the time forward by the time passed in.
    ApplySave: (dt, save, reverse) ->
        if reverse != true
            reverse = false

        @ApplyOffset dt, { negative: true, hours: save.hours, mins: save.mins, secs: 0}, reverse

    UTCToWallTime: (dt, offset, save) ->
        # Apply the gmt offset to the endTime
        # This is the "standard" time; offset but without daylight savings rules applied
        endTime = @UTCToStandardTime dt, offset

        # Apply the daylight savings to the offset
        # Moves the clock forward the amount of time in 'save'
        @ApplySave endTime, save

    UTCToStandardTime: (dt, offset) ->
        # Apply the gmt offset to the endTime because all our dates are represented with UTC underneath
        @ApplyOffset dt, offset, true

    UTCToQualifiedTime: (dt, qualifier, offset, getSave) ->
        endTime = dt
        switch qualifier
            when "w"
                # Wall Time, apply gmt offset then daylight savings
                endTime = @UTCToWallTime endTime, offset, getSave()
            when "s"
                # Standard Time, apply gmt offset only
                endTime = @UTCToStandardTime endTime, offset
            else
                # already in utc time, so nothing to do.

        endTime

    QualifiedTimeToUTC: (dt, qualifier, offset, getSave) ->
        endTime = dt
        switch qualifier
            when "w"
                # Wall Time, apply gmt offset then daylight savings
                endTime = @WallTimeToUTC offset, getSave(), endTime
            when "s"
                # Standard Time, apply gmt offset only
                endTime = @StandardTimeToUTC offset, endTime
            else
                # already in utc time, so nothing to do.

        endTime

    StandardTimeToUTC: (offset, y, m = 0, d = 1, h = 0, mi = 0, s = 0, ms = 0) ->
        dt = if typeof y == "number" then @MakeDateFromParts y, m, d, h, mi, s, ms else y
        # Jump up the gmt Offset
        @ApplyOffset dt, offset

    WallTimeToUTC: (offset, save, y, m = 0, d = 1, h = 0, mi = 0, s = 0, ms = 0) ->
        dt = @StandardTimeToUTC offset, y, m, d, h, mi, s, ms
        # Jump back the save value
        @ApplySave dt, save, true

    # Make a date from the passed in parts
    MakeDateFromParts: (y, m = 0, d = 1, h = 0, mi = 0, s = 0, ms = 0) ->
        if Date.UTC
            return new Date(Date.UTC y, m, d, h, mi, s, ms)

        # Handle browsers with no Date.UTC
        dt = new Date
        dt.setUTCFullYear y
        dt.setUTCMonth m
        dt.setUTCDate d
        dt.setUTCHours h
        dt.setUTCMinutes mi
        dt.setUTCSeconds s
        dt.setUTCMilliseconds ms

        # return the date
        dt

    LocalDate: (offset, save, y, m = 0, d = 1, h = 0, mi = 0, s = 0, ms = 0) ->
        @WallTimeToUTC offset, save, y, m, d, h, mi, s, ms

    # Make a date from a millisecond timestamp
    MakeDateFromTimeStamp: (ts) ->
        new Date(ts)

    MaxDate: ->
        # Sun, 26 Jan 29349 00:00:00 GMT
        @MakeDateFromTimeStamp 10000000*86400000
    MinDate: ->
        # Mon, 06 Dec -25410 00:00:00 GMT
        @MakeDateFromTimeStamp -10000000*86400000

helpers =
    Days: Days
    Months: Months
    Milliseconds: Milliseconds
    Time: Time
    noSave:
        hours: 0
        mins: 0
    noZone:
        offset:
            negative: false
            hours: 0
            mins: 0
            secs: 0
        name: "UTC"

if typeof window == 'undefined'
    module.exports = helpers
else if typeof define != 'undefined'
    define helpers
else
    @.WallTime or= {}
    @.WallTime.helpers = helpers