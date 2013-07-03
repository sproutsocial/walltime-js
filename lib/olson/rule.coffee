

init = (helpers, TimeZoneTime) ->

    # Handles a straight number for the on field of a rule.
    class NumberOnFieldHandler
        applies: (str) -> !isNaN(parseInt(str, 10))
        parseDate: (str) -> parseInt(str, 10)

    # Handles a "lastSun" type of value for the on field of a rule
    class LastOnFieldHandler
        applies: helpers.Months.IsLastDayOfMonthRule
        parseDate: (str, year, month, qualifier, gmtOffset, daylightOffset) ->
            helpers.Months.LastDayOfMonthRule str, year, month

    # Handles a "Sun>=8" type of value for the on field of a rule
    class CompareOnFieldHandler
        applies: helpers.Months.IsDayOfMonthRule
        parseDate: (str, year, month) ->
            helpers.Months.DayOfMonthByRule str, year, month

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

            @onUTC = helpers.Time.QualifiedTimeToUTC @onUTC, @atQualifier, offset, => getPrevSave(@)
            
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
        constructor: (@rules = [], @timeZone) ->
            # Update the rules offsets
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
                # Return begin of year save if this is the first rule (or not found)
                if idx < 1
                    if rules.length < 1
                        return helpers.noSave

                    # TODO: We are cheating here by choosing the last rule for the current year,
                    # we should have to check the previous years last rule.
                    return rules.slice(-1)[0].save

                # Return the previous rules save value otherwise
                rules[idx-1].save

            # Update the onTimes for each of the rules
            for rule in rules
                rule.setOnUTC dt.getUTCFullYear(), @timeZone.offset, getPrevRuleSave

            # Get rules that applied to us
            appliedRules = (rule for rule in rules when rule.onUTC.getTime() < dt.getTime())

            # TODO: We are cheating here by choosing the last rule for the current year,
            # we should have to check the previous years last rule.
            lastSave = if rules.length < 1 then helpers.noSave else rules.slice(-1)[0].save
            if appliedRules.length > 0
                # Get the last rule that applied, then use its save time
                lastSave = appliedRules.slice(-1)[0].save

            new TimeZoneTime(dt, @timeZone, lastSave)

        getUTCForWallTime: (dt) ->
            # All of our rule begins and ends are in UTC time, so try to translate at least by the offset.
            utcStd = helpers.Time.StandardTimeToUTC @timeZone.offset, dt
            rules = (rule for rule in @rules when rule.appliesToUTC utcStd)

            # If no rules apply, return standard time
            if rules.length < 1
                return utcStd

            # Sort the rules.
            rules = @_sortRulesByOnTime rules

            getPrevRuleSave = (r) ->
                idx = rules.indexOf r
                # Return begin of year save if this is the first rule (or not found)
                if idx < 1
                    if rules.length < 1
                        return helpers.noSave

                    # TODO: We are cheating here by choosing the last rule for the current year,
                    # we should have to check the previous years last rule.
                    return rules.slice(-1)[0].save

                # Return the previous rules save value otherwise
                rules[idx-1].save

            # Update the onTimes for each of the rules
            for rule in rules
                rule.setOnUTC utcStd.getUTCFullYear(), @timeZone.offset, getPrevRuleSave

            # Get rules that applied to us
            appliedRules = (rule for rule in rules when rule.onUTC.getTime() < utcStd.getTime())

            # TODO: We are cheating here by choosing the last rule for the current year,
            # we should have to check the previous years last rule.
            lastSave = if rules.length < 1 then helpers.noSave else rules.slice(-1)[0].save
            if appliedRules.length > 0
                # Get the last rule that applied, then use its save time
                lastSave = appliedRules.slice(-1)[0].save

            helpers.Time.WallTimeToUTC @timeZone.offset, lastSave, dt

        getYearEndDST: (dt) ->
            year = if typeof dt == number then dt else dt.getUTCFullYear()
            # Get the last second of the passed in year.
            utcStd = helpers.Time.StandardTimeToUTC @timeZone.offset, year, 11, 31, 23, 59, 59
            rules = (rule for rule in @rules when rule.appliesToUTC utcStd)

            # If no rules apply, return no save
            if rules.length < 1
                return helpers.noSave

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
                rule.setOnUTC utcStd.getUTCFullYear(), @timeZone.offset, getPrevRuleSave

            # Get rules that applied to us
            appliedRules = (rule for rule in rules when rule.onUTC.getTime() < utcStd.getTime())

            # Return no save if no rules applied.
            lastSave = helpers.noSave
            if appliedRules.length > 0
                # Get the last rule that applied, then use its save time
                lastSave = appliedRules.slice(-1)[0].save

            # Return the lastSave that applied
            lastSave

        isAmbiguous: (dt) ->
            # Get the standard version of the wall time that is passed in.
            utcStd = helpers.Time.StandardTimeToUTC @timeZone.offset, dt
            rules = (rule for rule in @rules when rule.appliesToUTC utcStd)

            # If no rules apply, return false
            if rules.length < 1
                return false

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
                rule.setOnUTC utcStd.getUTCFullYear(), @timeZone.offset, getPrevRuleSave

            # Get rules that applied to
            appliedRules = (rule for rule in rules when rule.onUTC.getTime() <= utcStd.getTime()-1)

            # Return false if no rules applied
            return false if appliedRules.length < 1
            
            # Get the last rule that applied, then check it's end time
            lastRule = appliedRules.slice(-1)[0]
            
            prevSave = getPrevRuleSave lastRule
            totalMinutes =
                prev: (prevSave.hours * 60) + prevSave.mins
                last: (lastRule.save.hours * 60) + lastRule.save.mins

            # There was no change in save, so there can be no ambiguity here.
            return false if totalMinutes.prev == totalMinutes.last

            # if the previous rule had a dst, and this one doesn't, it's a "fall back"
            # if the previous rule had no dst and this one does it's a "spring forward"
            springForward = totalMinutes.prev < totalMinutes.last

            makeAmbigRange = (begin, minutesOff) ->
                ambigRange =
                    begin: helpers.Time.MakeDateFromTimeStamp begin.getTime() + 1
                    
                ambigRange.end = helpers.Time.Add ambigRange.begin, 0, minutesOff

                # Since we could have applied a -minutesOff, switch the begin and end if they have swapped.
                if ambigRange.begin.getTime() > ambigRange.end.getTime()
                    tmp = ambigRange.begin
                    ambigRange.begin = ambigRange.end
                    ambigRange.end = tmp

                ambigRange

            # if we are springing forward, the last rules save should be added to determine the range
            # if we are falling back, the previous save should be used to set the beginning.
            minsOff = if springForward then totalMinutes.last else -totalMinutes.prev

            range = makeAmbigRange lastRule.onUTC, minsOff

            # Apply the previous save value to the standard time for fair comparison
            utcStd = helpers.Time.WallTimeToUTC @timeZone.offset, prevSave, dt

            # Return whether or not we are in the ambiguous range
            range.begin <= utcStd <= range.end

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

    lib

if typeof window == 'undefined'
    req_helpers = require "./helpers"
    req_TimeZoneTime = require "./timezonetime"
    module.exports = init(req_helpers, req_TimeZoneTime)
else if typeof define != 'undefined'
    define ["olson/helpers", "olson/timezonetime"], init
else
    @.WallTime or= {}
    @.WallTime.rule = init(@.WallTime.helpers, @.WallTime.TimeZoneTime)
            
