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
    parseDate: (str, year, month) ->
        # Get the last day with a matching name
        dayName = str[4..]
        # TODO: Always has a capital first letter?
        dayIndex = Days.DayIndex dayName

        # To get the last day of the month we set the date to the first day of next month, and move back one day.
        
        # Set the date to the first day of the next month
        if month < 11
            lastDay = new Date year, (month + 1)
        else 
            # Account for going over to the next year.
            lastDay = new Date year + 1, 0

        # Move back one day to the last day of the current month.
        lastDay = Days.AddToDate lastDay, -1

        # Iterate backward until our dayIndex matches the last days index
        lastDay = Days.AddToDate lastDay, -1 until lastDay.getDay() == dayIndex
        
        return lastDay.getDate()

# Handles a "Sun>=8" type of value for the on field of a rule
class CompareOnFieldHandler
    _onCompareRuleMatch: new RegExp "([a-zA-Z]*)([\\<\\>]?=)([0-9]*)"
    applies: (str) -> str.indexOf(">") > -1 or str.indexOf("<") > -1 or str.indexOf("=") > -1
    parseDate: (str, year, month) ->
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
        testDate = new Date year, month

        # Go forward one day at a time until we get a matching day of the week (Sun) and the compare of the date of the month passes (8 >= 8)
        testDate = Days.AddToDate testDate, 1 until dayIndex == testDate.getDay() and compareFunc(testDate.getDate(), dateIndex)

        return testDate.getDate()

# A Rule represents an Olson file line describing both a state of time for a given TimeZone
# and a transition to daylight savings offset.
class Rule
    constructor: (@name, @_from, @_to, @type, @in, @on, @at, @save, @letter) ->
        fromYear = parseInt @_from, 10
        
        toYear = if @_to == "only" then fromYear else parseInt @_to, 10
        toMonth = Months.MonthIndex @in
        onParsed = parseInt @on, 10
        toDay = if !isNaN(onParsed) then onParsed else @_parseOnDay @on, toYear, toMonth
        
        [saveHour, saveMinute] = @_parseTime @save
        @save = 
            hours: saveHour
            minutes: saveMinute
        
        
        [toHour, toMinute, atQualifier] = @_parseTime @at
        # If there was an at qualifier like s, u, g, or z we should keep that for later
        # Otherwise we default to the "Wall Time"
        @atQualifier = if atQualifier != '' then atQualifier else "w"

        # The end time here is not inclusive, it should be 1 millisecond less
        # Adjust the end time appropriately
        endTs = new Date(toYear, toMonth, toDay, toHour, toMinute, 0, 0).getTime() - 1
        endTime = new Date(endTs)

        @range =
            begin: new Date(fromYear, 0, 1)
            end: endTime

    # Parse the string that represents the day of the month in the "on" field of a rule.
    # In addition to an actual number this can be strings like "lastSun", "Sun>=8" representing
    # the last Sunday of the month or the first Sunday on or after the 8th day of the month (second Sunday of the month)
    _parseOnDay: (onStr, year, month) ->
        
        handlers = [new NumberOnFieldHandler, new LastOnFieldHandler, new CompareOnFieldHandler]

        for handler in handlers
            continue unless handler.applies onStr

            return handler.parseDate onStr, year, month

        throw new Error "Unable to parse 'on' field for #{@name}|#{@_from}|#{@_to}|#{onStr}"

    _parseTime: (atStr) ->
        helpers.Time.ParseTime atStr

    
class RuleSet
    constructor: (@rules, @timeZone) ->
        # TODO: Is there an order that these should be sorted by?

    allThatAppliesTo: (dt, getCurrentSaveState) ->
        
        (rule for rule in @rules when @_checkRuleApplicability rule, dt, getCurrentSaveState)

    checkRuleApplicability: (rule, dt, getCurrentSaveState) ->
        # We assume the date that is passed in is the "Wall Time" of that date.
        
        # TODO: Maybe move these into RuleQualifier Classes

        # Easy checks first?
        # If we are before the beginning of this date, return false
        dTimeStamp = dt.getTime()
        return false if dTimeStamp < rule.range.begin.getTime()

        # If the end time is wall time, just compare that we are before or equal to it
        return dTimeStamp <= rule.range.end.getTime() if rule.atQualifier is "w"

        # If the end time is standard or utc, we have to know if we are currently in daylight savings or not.
        # To do this we need to travel to the previous rule and see if there was a SAVE applied
        # We'll use the passed in function to tell us what the previous rule was so that we don't need to know about all the other rules that exist.
        saveState = getCurrentSaveState rule, dt
        stdDt = dt
        if saveState
            # Create an offset and apply it
            offset =
                # The offset here is always negative because SAVE indicates that we moved forward
                negative: true
                hours: saveState.hours
                mins: saveState.mins
                secs: 0

            # We need to adjust for daylight savings if the current wall time is in daylight savings
            stdDt = helpers.Time.ApplyOffset dt, offset

        # qualifiers g, u, z all mean UTC
        if ["g", "u", "z"].indexOf(rule.atQualifier) >= 0
            # If the end is UTC we need to convert the "wall time" to a UTC time
            # then compare to the end time
            utcDt = helpers.Time.ApplyOffset stdDt, @timeZone.offset

            return utcDt.getTime() <= rule.range.end.getTime()

        # Fall through to standard date comparison
        return stdDt.getTime() <= rule.range.end.getTime()



module.exports = 
    Rule: Rule
    RuleSet: RuleSet
    OnFieldHandlers:
        NumberHandler: NumberOnFieldHandler
        LastHandler: LastOnFieldHandler
        CompareHandler: CompareOnFieldHandler

            