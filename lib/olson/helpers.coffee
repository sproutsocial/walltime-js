# Some helpers for going between day names and indices.
Days = 
    DayShortNames: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    DayIndex: (name) ->
        @DayShortNames.indexOf name
    DayNameFromIndex: (dayIdx) ->
        @DayShortNames[dayIdx]
    AddToDate: (dt, days) ->
        new Date dt.getTime() + days * 24 * 60 * 60 * 1000

# Some helpers for going between month names and indices
Months = 
    MonthsShortNames: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    MonthIndex: (shortName) ->
        @MonthsShortNames.indexOf shortName

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

        # Inject in whether
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
        timeParts

    # Applies a GMT Style Offset.  -5:50:36 would return a new time that is 5 hours, 50 minutes and 36 seconds ahead of the passed in one
    # This is used to reconcile a date to UTC time
    ApplyOffset: (dt, offset) ->
        offset_ms = (Milliseconds.inHour * offset.hours) + (Milliseconds.inMinute * offset.mins) + (Milliseconds.inSecond * offset.secs)

        offset_ms = offset_ms * -1 if !offset.negative

        new Date(dt.getTime() + offset_ms)

    MaxDate: ->
        new Date(100000000*86400000)

module.exports = 
    Days: Days
    Months: Months
    Time: Time