should = require "should"
helpers = require "../lib/olson/helpers"
OlsonReader = require "../lib/olson/reader"
OlsonCommon = require "../lib/olson/common"
WallTime = require "../lib/walltime"
TimeZoneTime = require "../lib/olson/timezonetime"
OlsonZone = OlsonCommon.Zone
OlsonZoneSet = OlsonCommon.ZoneSet

describe "timezonetime", ->
    rules = {}
    zones = {}

    Feb12_2013_235  = 1360658127000
    Feb12_2013_414  = 1360664067000
    Feb12_2013_1135 = 1360690527000

    Feb12_2013_1433 = 1360701207000
    Feb12_2013_1714 = 1360710867000
    Feb11_2013_2333 = 1360647207000
    

    readTimezoneFile = (file = "./test/rsrc/full/northamerica", next) ->
        reader = new OlsonReader

        reader.singleFile file, (result) ->
            should.exist result?.zones, "should have zones in result"
            should.exist result?.rules, "should have rules in result"

            rules = JSON.parse(JSON.stringify(result.rules))
            # zones = JSON.parse(JSON.stringify(result.zones))

            zones[zoneName] = zoneVal.zones for own zoneName, zoneVal of result.zones

            do next

    beforeEach ->
        WallTime.rules = undefined
        WallTime.zones = undefined
        WallTime.doneInit = false

    describe "toFormattedTime", ->
        before (next) ->
            readTimezoneFile "./test/rsrc/full/northamerica", next

        it "processes am dates properly in 12 hour time", ->
            WallTime.init rules, zones

            WallTime.setTimeZone "America/Chicago"

            date = WallTime.UTCToWallTime Feb12_2013_235
            date.toFormattedTime().should.equal "2:35 AM"

            date = WallTime.UTCToWallTime Feb12_2013_414
            date.toFormattedTime().should.equal "4:14 AM"

            date = WallTime.UTCToWallTime Feb12_2013_1135
            date.toFormattedTime().should.equal "11:35 AM"

        it "processes pm dates properly in 12 hour time", ->
            WallTime.init rules, zones

            WallTime.setTimeZone "America/Chicago"

            date = WallTime.UTCToWallTime Feb12_2013_1433
            date.toFormattedTime().should.equal "2:33 PM"

            date = WallTime.UTCToWallTime Feb12_2013_1714
            date.toFormattedTime().should.equal "5:14 PM"

            date = WallTime.UTCToWallTime Feb11_2013_2333
            date.toFormattedTime().should.equal "11:33 PM"

        it "processes am dates properly in 24 hour time", ->
            WallTime.init rules, zones

            WallTime.setTimeZone "America/Chicago"

            date = WallTime.UTCToWallTime Feb12_2013_235
            date.toFormattedTime(true).should.equal "2:35"

            date = WallTime.UTCToWallTime Feb12_2013_414
            date.toFormattedTime(true).should.equal "4:14"

            date = WallTime.UTCToWallTime Feb12_2013_1135
            date.toFormattedTime(true).should.equal "11:35"

        it "processes pm dates properly in 24 hour time", ->
            WallTime.init rules, zones

            WallTime.setTimeZone "America/Chicago"

            date = WallTime.UTCToWallTime Feb12_2013_1433
            date.toFormattedTime(true).should.equal "14:33"

            date = WallTime.UTCToWallTime Feb12_2013_1714
            date.toFormattedTime(true).should.equal "17:14"

            date = WallTime.UTCToWallTime Feb11_2013_2333
            date.toFormattedTime(true).should.equal "23:33"
