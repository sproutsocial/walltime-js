

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
    MonthIndex: (shortName) ->
        @MonthsShortNames.indexOf shortName.slice(0, 3)

Milliseconds = 
    inDay:    86400000
    inHour:   3600000
    inMinute: 60000
    inSecond: 1000

# Some helpers for dealing with time values
Time = 
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

    # Applies a GMT Style Offset.  -5:50:36 would return a new time that is 5 hours, 50 minutes and 36 seconds behind the passed in one
    # This is used to reconcile a UTC time to standard time, however, if reverse is passed we can convert from GMT Standard time to UTC
    ApplyOffset: (dt, offset, reverse) ->
        offset_ms = (Milliseconds.inHour * offset.hours) + (Milliseconds.inMinute * offset.mins) + (Milliseconds.inSecond * offset.secs)

        offset_ms = offset_ms * -1 if offset.negative

        if reverse
            offset_ms = offset_ms * -1

        @MakeDateFromTimeStamp(dt.getTime() + offset_ms)

    # Applies a SAVE value by adjusting the time forward by the time passed in.
    ApplySave: (dt, save) ->
        @ApplyOffset dt, { negative: false, hours: save.hours, mins: save.mins, secs: 0}

    UTCToWallTime: (dt, offset, save) ->
        # Apply the gmt offset to the endTime
        # This is the "standard" time; offset but without daylight savings rules applied
        endTime = @UTCToStandardTime dt, offset

        # Apply the daylight savings to the offset
        # Moves the clock forward the amount of time in 'save'
        @ApplySave endTime, save

    UTCToStandardTime: (dt, offset) ->
        # Apply the gmt offset to the endTime because all our dates are represented with UTC underneath
        @ApplyOffset dt, offset

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

    StandardTimeToUTC: (offset, y, m = 0, d = 1, h = 0, mi = 0, s = 0, ms = 0) ->
        dt = @MakeDateFromParts y, m, d, h, mi, s, ms
        # Jump up the gmt Offset
        @ApplyOffset dt, offset

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
else
    define "helpers", helpers