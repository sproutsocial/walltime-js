should = require "should"
helpers = require "../lib/olson/helpers"
OlsonReader = require "../lib/olson/reader"
OlsonCommon = require "../lib/olson/common"
Handlers = (require "../lib/olson/rule").OnFieldHandlers
OlsonRule = OlsonCommon.Rule
OlsonRuleSet = OlsonCommon.RuleSet

describe "Olson Rules", ->
    reader = new OlsonReader
    ruleLine = "rule\tChicago\t1920\tonly\t-\tJun\t13\t2:00\t1:00\tD"
    atUTCRuleLine = "rule\tChicago\t1920\tonly\t-\tJun\t13\t23:00u\t1:00\tD"
    atSTDRuleLine = "rule\tChicago\t1920\tonly\t-\tJun\t13\t23:00s\t1:00\tD"

    rule = reader.processRuleLine ruleLine

    describe "'on' Field Handlers", ->
        numberHandler = new Handlers.NumberHandler
        lastHandler = new Handlers.LastHandler
        compareHandler = new Handlers.CompareHandler

        commonHandlerTest = (str, year, month, handler, expectApply, expectResult) ->
            applies = handler.applies str, year, month
            applies.should.equal expectApply, "applies"
            return unless applies

            offset =
                negative: true
                hours: 6
                mins: 0
                secs: 0

            save = 
                hours: 1
                mins: 0

            qualifier = "w"

            expectResult.should.equal handler.parseDate(str, year, month, qualifier, offset, save), "parseDate - #{str}"

        it "handles specific date fields", ->
            commonHandlerTest "13", 1920, 5, numberHandler, true, 13
            commonHandlerTest "lastSun", 1920, 5, numberHandler, false, 0
            commonHandlerTest "Fri>=8", 1920, 5, numberHandler, false, 0

        it "handles last day fields (lastSun)", ->
            commonHandlerTest "lastSun", 1920, 9, lastHandler, true, 31
            commonHandlerTest "124", 1920, 9, lastHandler, false
            commonHandlerTest "Sat>=1", 1920, 9, lastHandler, false

        it "handles compare fields (Sun>=8)", ->
            commonHandlerTest "Sun>=1", 1920, 9, compareHandler, true, 3
            commonHandlerTest "Sun>=8", 1920, 9, compareHandler, true, 10
            commonHandlerTest "Sun>=10", 1920, 9, compareHandler, true, 10
            commonHandlerTest "Sun>=11", 1920, 9, compareHandler, true, 17

            commonHandlerTest "13", 1920, 9, compareHandler, false
            commonHandlerTest "lastSun", 1920, 9, compareHandler, false

    it "can calculate it's range", ->
        
        begin = helpers.Time.MakeDateFromParts(1920, 0, 1, 0, 0)
        # End times are compared in qualified time
        end = helpers.Time.UTCToQualifiedTime helpers.Time.MakeDateFromParts(1920, 5, 13, 1, 59, 59, 999), rule.atQualifier, rule.gmtOffset, rule.save
        rule.range.begin.should.equal begin, "begin"
        rule.range.end.should.equal end, "end"

    ruleTime = (r, dt) ->
        helpers.Time.UTCToQualifiedTime dt, r.atQualifier, r.gmtOffset, r.save

    commonRangeTest = (r, date, expected, msg) ->
        timeZone = 
            offset:
                negative: true
                hours: 5
                mins: 0
                secs: 0
        set = new OlsonRuleSet([rule], timeZone)
        prevRuleState = 
            negative: false
            hours: 1
            mins: 0
            secs: 0

        actual = set.checkRuleApplicability r, date, -> prevRuleState
        actual.should.equal expected, "#{msg}: #{date.toUTCString()} - #{JSON.stringify(r)}"

    it "can tell when a date falls within it's range for wall time", ->

        # Before
        commonRangeTest rule, helpers.Time.RuleTimeToUTC(rule, 1919, 11, 31, 23, 59, 59, 999), false, "before"
        # Beginning
        commonRangeTest rule, helpers.Time.RuleTimeToUTC(rule, 1920, 0, 1, 0, 0), true, "beginning"
        # Middle
        commonRangeTest rule, helpers.Time.RuleTimeToUTC(rule, 1920, 2, 1, 0, 0), true, "middle"
        # End
        commonRangeTest rule, helpers.Time.RuleTimeToUTC(rule, 1920, 5, 13, 1, 59, 59, 999), true, "end"
        # After
        commonRangeTest rule, helpers.Time.RuleTimeToUTC(rule, 1920, 5, 13, 2, 0, 0), false, "after"

    it "can tell when a date falls within it's range for utc time", ->
        # Set up a utc Rule for 
        utcRule = reader.processRuleLine atUTCRuleLine
        
        # Before
        commonRangeTest utcRule, helpers.Time.RuleTimeToUTC(utcRule, 1919, 11, 31, 23, 59, 59, 999), false, "before"
        # Beginning
        commonRangeTest utcRule, helpers.Time.RuleTimeToUTC(utcRule, 1920, 0, 1, 0, 0), true, "beginning"
        # Middle
        commonRangeTest utcRule, helpers.Time.RuleTimeToUTC(utcRule, 1920, 2, 1, 0, 0), true, "middle"
        # End (With daylight savings already being applied)
        commonRangeTest utcRule, helpers.Time.RuleTimeToUTC(utcRule, 1920, 5, 13, 16, 59, 59, 999), true, "end"
        # After (With daylight savings already being applied)
        commonRangeTest utcRule, helpers.Time.RuleTimeToUTC(utcRule, 1920, 5, 13, 17, 0, 0), false, "after"




