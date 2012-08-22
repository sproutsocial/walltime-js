if typeof window == 'undefined'
    helpers = require "./helpers"
    TimeZoneTime = require "./timezonetime"

# Handles a straight number for the on field of a rule.
class NumberOnFieldHandler
    applies: (str) -> !isNaN(parseInt(str, 10))
    parseDate: (str) -> parseInt(str, 10)

# Handles a "lastSun" type of value for the on field of a rule
class LastOnFieldHandler
    applies: (str) -> str[0..3] == "last"
    parseDate: (str, year, month, qualifier, gmtOffset, daylightOffset) ->
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

        return testDate.getUTCDate()

# A Rule represents an Olson file line describing both a state of time for a given TimeZone
# and a transition to daylight savings offset.
class Rule
    constructor: (@name, @_from, @_to, @type, @in, @on, @at, @_save, @letter) ->
        @from = parseInt @_from, 10

        @isMax = false
        toYear = @from
        switch @_to
            when "max"
                toYear = (helpers.Time.MaxDate()).getUTCFullYear()
                @isMax = true
            when "only"
                toYear = @from
            else
                toYear = parseInt @_to, 10

        @to = toYear

        [saveHour, saveMinute] = @_parseTime @_save
        @save = 
            hours: saveHour
            mins: saveMinute

    forZone: (offset) ->
        @offset = offset

        # Start with the beginning of the year UTC
        @fromUTC = helpers.Time.MakeDateFromParts @from, 0, 1, 0, 0, 0
        # Apply the passed in time zones offset to get the standard time equivalent of the beginning of the year.
        @fromUTC = helpers.Time.ApplyOffset @fromUTC, offset
        
        # To is the end of the passed in To year, adjusted for GMTOffset and Daylight savings
        @toUTC = helpers.Time.MakeDateFromParts @to, 11, 31, 23, 59, 59, 999
        @toUTC = helpers.Time.ApplyOffset @toUTC, offset

    setOnUTC: (year, offset, getPrevSave) ->
        toMonth = helpers.Months.MonthIndex @in
        onParsed = parseInt @on, 10
        toDay = if !isNaN(onParsed) then onParsed else @_parseOnDay @on, year, toMonth

        # Get the time of day and apply it to the onUTC
        [toHour, toMinute, atQualifier] = @_parseTime @at
        # The end time here is not inclusive, we adjust it by 1 millisecond
        @onUTC = helpers.Time.MakeDateFromParts year, toMonth, toDay, toHour, toMinute
        @onUTC.setUTCMilliseconds(@onUTC.getUTCMilliseconds() - 1)

        @atQualifier = if atQualifier != '' then atQualifier else "w"

        @onUTC = helpers.Time.UTCToQualifiedTime @onUTC, @atQualifier, offset, => getPrevSave(@)

        @onSort = "#{toMonth}-#{toDay}-#{@onUTC.getUTCHours()}-#{@onUTC.getUTCMinutes()}"     

    appliesToUTC: (dt) ->
        @fromUTC <= dt <= @toUTC

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
        # Update the rules offsets
        index = 0
        min = null
        max = null
        endYears = {}
        beginYears = {}
        for rule in @rules
            # In the first pass through, we won't have accurate end's
            rule.forZone @timeZone.offset, -> helpers.noSave
            if min == null or rule.from < min
                min = rule.from
            if max == null or rule.to > max
                max = rule.to

            endYears[rule.to] = endYears[rule.to] || []
            endYears[rule.to].push rule
            beginYears[rule.from] = beginYears[rule.from] || []
            beginYears[rule.from].push rule
            index++

        # Store these for later range checks on rules.
        @minYear = min
        @maxYear = max

        commonUpdateYearEnds = (end = "toUTC", years = endYears) =>
            for own year, rules of years
                # Get the rules that apply for that year
                yearRules = @allThatAppliesTo rules[0][end]
                
                continue if yearRules.length < 1

                # We only care about the last rule that gets applied for the year
                # We need to sort here by the on time 
                # TODO: (kind of cheating by only sorting by month)
                rules = @_sortRulesByOnTime rules
                lastRule = yearRules.slice(-1)[0]

                # Keep it moving if no save to apply
                continue if lastRule.save.hours == 0 and lastRule.save.mins == 0

                for rule in rules
                    rule[end] = helpers.Time.ApplySave rule[end], lastRule.save

        # Follow up and check each end year for a last rule with a save value.
        commonUpdateYearEnds "toUTC", endYears

        # The begin times could also have a save applied that we missed.
        commonUpdateYearEnds "fromUTC", beginYears

    allThatAppliesTo: (dt) ->
        # TODO: Pre-check for year outside of min and max.

        (rule for rule in @rules when rule.appliesToUTC dt)

    getWallTimeForUTC: (dt) ->
        # Get the rules for this year
        rules = @allThatAppliesTo dt

        # If no rules apply, return standard time
        if rules.length < 1
            return new TimeZoneTime(dt, @timeZone, helpers.noSave)

        # Sort the rules.
        rules = @_sortRulesByOnTime rules

        getPrevRuleSave = (r) ->
            idx = rules.indexOf r
            # Return no save if this is the first rule (or not found)
            if idx < 1
                return helpers.noSave

            # Return the previous rules save value otherwise
            rules[idx-1].save

        # Update the onTimes for each of the rules
        for rule in rules
            rule.setOnUTC dt.getUTCFullYear(), @timeZone.offset, getPrevRuleSave

        # Get rules that applied to us
        appliedRules = (rule for rule in rules when rule.onUTC.getTime() < dt.getTime())

        # Return the standard time if no rules applied.
        lastSave = helpers.noSave
        if appliedRules.length > 0
            # Get the last rule that applied, then use its save time
            lastSave = appliedRules.slice(-1)[0].save

        new TimeZoneTime(dt, @timeZone, lastSave)

    _sortRulesByOnTime: (rules) ->
        rules.sort (a, b) ->
            (helpers.Months.MonthIndex a.in) - (helpers.Months.MonthIndex b.in)

lib = 
    Rule: Rule
    RuleSet: RuleSet
    OnFieldHandlers:
        NumberHandler: NumberOnFieldHandler
        LastHandler: LastOnFieldHandler
        CompareHandler: CompareOnFieldHandler

if typeof window == 'undefined'
    module.exports = lib
else
    define ["helpers", "TimeZoneTime"], "rule", lib
            