should = require "should"

helpers = require "../lib/olson/helpers"
OlsonReader = require "../lib/olson/reader"
{OlsonZone, OlsonZoneSet} = require "../lib/olson/common"
WallTime = require "../lib/walltime"
TimeZoneTime = require "../lib/olson/timezonetime"

describe "timezonetime", ->
    rules = {}
    zones = {}

    Feb12_2013_235  = 1360658127000
    Feb12_2013_414  = 1360664067000
    Feb12_2013_1135 = 1360690527000

    Feb12_2013_1433 = 1360701207000
    Feb12_2013_1714 = 1360710867000
    Feb11_2013_2333 = 1360647207000

    Mar14_2013_800 = 1363266000000
    

    readTimezoneFile = (file = "./test/rsrc/full/northamerica", next) ->
        reader = new OlsonReader

        reader.singleFile file, (result) ->
            should.exist result?.zones, "should have zones in result"
            should.exist result?.rules, "should have rules in result"

            for own ruleName, ruleVal of result.rules
                rules[ruleName] ||= []
                rules[ruleName] = rules[ruleName].concat ruleVal
            
            zones[zoneName] = zoneVal.zones for own zoneName, zoneVal of result.zones

            do next

    before (next) ->
        readTimezoneFile "./test/rsrc/full/northamerica", ->
            readTimezoneFile "./test/rsrc/full/etcetera", next

    beforeEach ->
        WallTime.rules = undefined
        WallTime.zones = undefined
        WallTime.doneInit = false

        WallTime.init rules, zones

        WallTime.setTimeZone "America/Chicago"

    it "implements toISOString() for non UTC times", ->
        date = WallTime.UTCToWallTime Feb12_2013_1433

        date.toISOString().should.equal "2013-02-12T20:33:27.000Z"

    it "implements toISOString() for UTC times", ->
        date = WallTime.UTCToWallTime Feb12_2013_1433, "Etc/UTC"

        date.toISOString().should.equal "2013-02-12T20:33:27.000Z"

    it "implements getTimezoneOffset()", ->
        date = WallTime.UTCToWallTime Feb12_2013_1433

        # 360 base offset
        expect = 360

        date.getTimezoneOffset().should.equal expect

        date = WallTime.UTCToWallTime Mar14_2013_800

        # 360 base offset - 60 daylight savings
        expect = 300

        date.getTimezoneOffset().should.equal expect, "dst"

    it "sets year correctly", ->
        date = WallTime.UTCToWallTime Feb12_2013_1433
        date.getFullYear().should.equal 2013
        
        date.setFullYear 2012

        date.getFullYear().should.equal 2012
        date.getMonth().should.equal 1
        date.getHours().should.equal 14

    it "sets month correctly", ->
        date = WallTime.UTCToWallTime Feb12_2013_1433
        date.getMonth().should.equal 1
        
        date.setMonth 0

        date.getMonth().should.equal 0
        date.getHours().should.equal 14

    it "sets day correctly", ->
        date = WallTime.UTCToWallTime Feb12_2013_1433
        date.getDate().should.equal 12
        
        date.setDate 1

        date.getFullYear().should.equal 2013
        date.getDate().should.equal 1
        date.getHours().should.equal 14

    it "sets hour correctly", ->
        date = WallTime.UTCToWallTime Feb12_2013_1433
        date.getHours().should.equal 14
        date.getFullYear().should.equal 2013

        date.setHours 7

        date.getHours().should.equal 7
        date.getFullYear().should.equal 2013

    it "sets minute correctly", ->
        date = WallTime.UTCToWallTime Feb12_2013_1433
        date.getMinutes().should.equal 33
        date.getFullYear().should.equal 2013

        date.setMinutes 13

        date.getMinutes().should.equal 13
        date.getFullYear().should.equal 2013

    it "sets seconds correctly", ->
        date = WallTime.UTCToWallTime Feb12_2013_1433
        date.getSeconds().should.not.equal 11
        date.getFullYear().should.equal 2013

        date.setSeconds 11

        date.getSeconds().should.equal 11
        date.getFullYear().should.equal 2013

    it "sets time correctly from timestamp", ->
        date = WallTime.UTCToWallTime Feb12_2013_1433
        date.getHours().should.equal 14
        date.getFullYear().should.equal 2013

        date.setTime Feb12_2013_1135
        
        date.getHours().should.equal 11
        date.getMinutes().should.equal 35
        date.getMonth().should.equal 1
        date.getFullYear().should.equal 2013

    describe "toFormattedTime", ->

        it "processes am dates properly in 12 hour time", ->
            date = WallTime.UTCToWallTime Feb12_2013_235
            date.toFormattedTime().should.equal "2:35 AM"

            date = WallTime.UTCToWallTime Feb12_2013_414
            date.toFormattedTime().should.equal "4:14 AM"

            date = WallTime.UTCToWallTime Feb12_2013_1135
            date.toFormattedTime().should.equal "11:35 AM"

        it "processes pm dates properly in 12 hour time", ->
            date = WallTime.UTCToWallTime Feb12_2013_1433
            date.toFormattedTime().should.equal "2:33 PM"

            date = WallTime.UTCToWallTime Feb12_2013_1714
            date.toFormattedTime().should.equal "5:14 PM"

            date = WallTime.UTCToWallTime Feb11_2013_2333
            date.toFormattedTime().should.equal "11:33 PM"

        it "processes am dates properly in 24 hour time", ->
            date = WallTime.UTCToWallTime Feb12_2013_235
            date.toFormattedTime(true).should.equal "2:35"

            date = WallTime.UTCToWallTime Feb12_2013_414
            date.toFormattedTime(true).should.equal "4:14"

            date = WallTime.UTCToWallTime Feb12_2013_1135
            date.toFormattedTime(true).should.equal "11:35"

        it "processes pm dates properly in 24 hour time", ->
            date = WallTime.UTCToWallTime Feb12_2013_1433
            date.toFormattedTime(true).should.equal "14:33"

            date = WallTime.UTCToWallTime Feb12_2013_1714
            date.toFormattedTime(true).should.equal "17:14"

            date = WallTime.UTCToWallTime Feb11_2013_2333
            date.toFormattedTime(true).should.equal "23:33"


