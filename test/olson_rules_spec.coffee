should = require "should"
helpers = require "../lib/olson/helpers"
OlsonCommon = require "../lib/olson/common"
Handlers = (require "../lib/olson/rule").OnFieldHandlers
OlsonRule = OlsonCommon.Rule
OlsonRuleSet = OlsonCommon.RuleSet


describe "Olson Rules", ->
    ruleLine = "rule\tChicago\t1920\tonly\t-\tJun\t13\t2:00\t1:00\tD"
    atUTCRuleLine = "rule\tChicago\t1920\tonly\t-\tJun\t13\t23:00u\t1:00\tD"
    atSTDRuleLine = "rule\tChicago\t1920\tonly\t-\tJun\t13\t23:00s\t1:00\tD"

    utcZone = 
        offset:
            negative: false
            hours: 0
            mins: 0
            secs: 0

    chiZone = 
        offset:
            negative: true
            hours: 6
            mins: 0
            secs: 0

    noSaveState = 
        hours: 0
        mins: 0
    dstSaveState =
        hours: 1
        mins: 0

    makeRule = -> new OlsonRule("Chicago", "1920", "only", "-", "Jun", "13", "2:00", "1:00", "D")
    #makeUtcRule = -> new OlsonRule("Chicago", "1920", "only", "-", "Jun", "13", "23:00u", "1:00", "D")
    #makeStdRule = -> new OlsonRule("Chicago", "1920", "only", "-", "Jun", "13", "23:00s", "1:00", "D")

    rule = makeRule()
    beforeEach: ->
        rule = makeRule()
    
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

    it "calculates the begin time in UTC without daylight savings offset", ->
        # Chicago zone (-5 Hour Offset) and no save state.
        rule.forZone chiZone.offset

        expected = helpers.Time.MakeDateFromParts rule.from, 0, 1
        expected = helpers.Time.ApplyOffset expected, chiZone.offset
        rule.fromUTC.should.equal expected, "Chi - No Save State"

    it "calculates the end time in UTC with daylight savings offset", ->
        rule.forZone chiZone.offset

        expected = helpers.Time.MakeDateFromParts rule.from, 11, 31, 23, 59, 59, 999
        expected = helpers.Time.ApplyOffset expected, chiZone.offset
        rule.toUTC.should.equal expected, "Chi - No Save State"

    describe "Sets", ->
        rules = [
            new OlsonRule("Chicago", "1920", "only", "-", "Jun", "13", "2:00", "1:00", "D"),
            new OlsonRule("Chicago", "1920", "1921", "-", "Oct", "lastSun", "2:00", "0", "S"),
            new OlsonRule("Chicago", "1921", "only", "-", "Mar", "lastSun", "2:00", "1:00", "D"),
            new OlsonRule("Chicago", "1922", "1922", "-", "Apr", "lastSun", "2:00", "1:00", "D"),
            new OlsonRule("Chicago", "1922", "1922", "-", "Sep", "lastSun", "2:00", "0", "S"),
            new OlsonRule("Chicago", "1925", "1955", "-", "Oct", "lastSun", "2:00", "0", "S")
        ]
            
        set = new OlsonRuleSet(rules, chiZone)

        commonWallTimeTest = (point, zone, save) ->
                result = set.getWallTimeForUTC point

                result.offset.hours.should.equal zone.offset.hours, "Offset hours"
                result.offset.mins.should.equal zone.offset.mins, "Offset mins"
                result.offset.secs.should.equal zone.offset.secs, "Offset secs"

                result.save.hours.should.equal save.hours
                result.save.mins.should.equal save.mins

                result.utc.should.equal point, "UTC time"

                expect = point
                expect = helpers.Time.UTCToWallTime point, result.offset, result.save

                result.wallTime.should.equal expect

        it "can tell what rules apply for a given UTC time", ->
            point = helpers.Time.StandardTimeToUTC chiZone.offset, 1920, 0, 1

            result = set.allThatAppliesTo point

            result.length.should.equal 2, "length"
            result[0].should.equal rules[0], "first rule"
            result[1].should.equal rules[1], "second rule"

        it "can get WallTime for before rules take effect", ->
            # Before any rules
            point = helpers.Time.MakeDateFromParts 1900, 0, 1

            commonWallTimeTest point, chiZone, noSaveState

        it "can get WallTime for beginning of year", ->
            # Beginning of year with 2 rules.
            point = helpers.Time.MakeDateFromParts 1920, 0, 1

            commonWallTimeTest point, chiZone, noSaveState

        it "can get WallTime for before dst rule takes effect", ->
            # Immediately before the dst rule
            point = helpers.Time.StandardTimeToUTC chiZone.offset, 1920, 5, 13, 1, 59, 59
            
            commonWallTimeTest point, chiZone, noSaveState

        it "can get WallTime with 1 hour saved for after dst rule", ->
            # Immediately after the daylight savings rule (second of)
            point = helpers.Time.StandardTimeToUTC chiZone.offset, 1920, 5, 13, 2, 0, 0
            
            commonWallTimeTest point, chiZone, dstSaveState

        it "can get WallTime for right before switching to no dst", ->

            # Immediately before the dst rule expires
            point = helpers.Time.WallTimeToUTC chiZone.offset, dstSaveState, 1920, 9, 31, 1, 59, 59
            
            commonWallTimeTest point, chiZone, dstSaveState

        it "can get WallTime for after dst expires", ->

            # Immediately after the dst rule expires
            point = helpers.Time.MakeDateFromParts 1920, 9, 31, 2, 0, 0
            point = helpers.Time.ApplyOffset point, chiZone.offset
            point = helpers.Time.ApplySave point, dstSaveState

            commonWallTimeTest point, chiZone, noSaveState





