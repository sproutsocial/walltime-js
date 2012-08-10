helpers = require "./helpers"
Days = helpers.Days
Months = helpers.Months

# Handles a straight number for the on field of a rule.
class NumberOnFieldHandler
    applies: (str) -> 
        !isNaN(parseInt(str, 10))
    parseDate: (str) -> parseInt(str, 10)

# Handles a "lastSun" type of value for the on field of a rule
class LastOnFieldHandler
    applies: (str) -> str[0..3] == "last"
    parseDate: (str, year, month, qualifier, gmtOffset, daylightOffset) ->
        # Get the last day with a matching name
        dayName = str[4..]
        # TODO: Always has a capital first letter?
        dayIndex = Days.DayIndex dayName

        # To get the last day of the month we set the date to the first day of next month, and move back one day.
        
        # Set the date to the first day of the next month
        if month < 11
            lastDay = helpers.Time.MakeDateFromParts year, (month + 1)
        else 
            # Account for going over to the next year.
            lastDay = helpers.Time.MakeDateFromParts year + 1, 0

        # Move back one day to the last day of the current month.
        lastDay = Days.AddToDate lastDay, -1

        # Iterate backward until our dayIndex matches the last days index
        while lastDay.getUTCDay() != dayIndex
            lastDay = Days.AddToDate lastDay, -1
        
        return lastDay.getUTCDate()

# Handles a "Sun>=8" type of value for the on field of a rule
class CompareOnFieldHandler
    _onCompareRuleMatch: new RegExp "([a-zA-Z]*)([\\<\\>]?=)([0-9]*)"
    applies: (str) -> str.indexOf(">") > -1 or str.indexOf("<") > -1 or str.indexOf("=") > -1
    parseDate: (str, year, month, qualifier, gmtOffset, daylightOffset) ->
        # Parse our onStr into the components
        ruleParse = @_onCompareRuleMatch.exec str

        if !ruleParse
            throw new Error "Unable to parse the 'on' rule for #{str}"

        # Whoa, destructured assignment? Hell yeah!
        [dayName, testPart, dateIndex] = ruleParse[1..3]

        dateIndex = parseInt dateIndex, 10
        if dateIndex is NaN
            throw new Error "Unable to parse the dateIndex of the 'on' rule for #{str}"
        
        dayIndex = Days.DayIndex dayName

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

        # We just need to find the day of the month, so no need to adjust for gmt offset.

        # Go forward one day at a time until we get a matching day of the week (Sun) and the compare of the date of the month passes (8 >= 8)
        while !(dayIndex == testDate.getUTCDay() and compareFunc(testDate.getUTCDate(), dateIndex))
            testDate = Days.AddToDate testDate, 1 
         

        return testDate.getUTCDate()

# A Rule represents an Olson file line describing both a state of time for a given TimeZone
# and a transition to daylight savings offset.
class Rule
    constructor: (@name, @_from, @_to, @type, @in, @on, @at, @_save, @letter, @gmtOffset = { negative: false, hours: 0, mins: 0, secs: 0 }) ->
        @from = parseInt @_from, 10

        [saveHour, saveMinute] = @_parseTime @_save
        @save = 
            hours: saveHour
            mins: saveMinute
        
        @updateRange @gmtOffset

    # Updates the begin and end times to reflect the zone offset being applied
    updateRange: (offset) ->
        @gmtOffset = offset
        @isMax = false
        switch @_to
            when "max"
                toYear = (helpers.Time.MaxDate()).getUTCFullYear()
                @isMax = true
            when "only"
                toYear = @from
            else
                toYear = parseInt @_to, 10

        [toHour, toMinute, atQualifier] = @_parseTime @at
        # If there was an at qualifier like s, u, g, or z we should keep that for later
        # Otherwise we default to the "Wall Time"
        @atQualifier = if atQualifier != '' then atQualifier else "w"

        toMonth = Months.MonthIndex @in
        onParsed = parseInt @on, 10
        toDay = if !isNaN(onParsed) then onParsed else @_parseOnDay @on, toYear, toMonth

        # The end time here is not inclusive, it should be 1 millisecond less
        # Adjust the end time appropriately
        endTime = helpers.Time.MakeDateFromParts toYear, toMonth, toDay, toHour, toMinute, 0, 0
        endTime.setUTCMilliseconds(endTime.getUTCMilliseconds() - 1)

        # this will convert our time to standard time
        endTime = helpers.Time.UTCToStandardTime endTime, @gmtOffset

        fromYear = parseInt @_from, 10
        begin = helpers.Time.MakeDateFromParts fromYear, 0, 1
        # Does this need to include the daylight savings from this rule or the previous one?
        #begin = helpers.Time.UTCToWallTime begin, @gmtOffset, @save
        begin = helpers.Time.UTCToStandardTime begin, @gmtOffset

        @range =
            begin: begin
            end: endTime


    # Parse the string that represents the day of the month in the "on" field of a rule.
    # In addition to an actual number this can be strings like "lastSun", "Sun>=8" representing
    # the last Sunday of the month or the first Sunday on or after the 8th day of the month (second Sunday of the month)
    _parseOnDay: (onStr, year, month, offset) ->
        
        handlers = [new NumberOnFieldHandler, new LastOnFieldHandler, new CompareOnFieldHandler]

        for handler in handlers
            continue unless handler.applies onStr

            return handler.parseDate onStr, year, month, @atQualifier, @gmtOffset, @save

        throw new Error "Unable to parse 'on' field for #{@name}|#{@_from}|#{@_to}|#{onStr}"

    _parseTime: (atStr) ->
        helpers.Time.ParseTime atStr

    
class RuleSet
    constructor: (@rules, @timeZone) ->
        # TODO: Is there an order that these should be sorted by?

        # Update the rules offsets
        rule.updateRange @timeZone.offset for rule in @rules

    allThatAppliesTo: (dt, getCurrentSaveState) ->
        
        (rule for rule in @rules when @_checkRuleApplicability rule, dt, getCurrentSaveState)

    checkRuleApplicability: (rule, dt, getCurrentSaveState) ->
        # We assume the date that is passed in is UTC Time
        
        # TODO: Maybe move these into RuleQualifier Classes

        # Convert the DT to the rules qualifier time and compare to end
        qualTime = helpers.Time.UTCToQualifiedTime dt, rule.atQualifier, rule.gmtOffset, getCurrentSaveState(rule, dt)

        # Easy checks first?
        # If we are before the beginning of this date, return false
        dTimeStamp = qualTime.getTime()
        return false if dTimeStamp < rule.range.begin.getTime()

        return dTimeStamp <= rule.range.end.getTime()

module.exports = 
    Rule: Rule
    RuleSet: RuleSet
    OnFieldHandlers:
        NumberHandler: NumberOnFieldHandler
        LastHandler: LastOnFieldHandler
        CompareHandler: CompareOnFieldHandler

            