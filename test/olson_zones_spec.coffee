should = require "should"
helpers = require "../lib/olson/helpers"
OlsonReader = require "../lib/olson/reader"
OlsonCommon = require "../lib/olson/common"
OlsonZone = OlsonCommon.Zone
OlsonZoneSet = OlsonCommon.ZoneSet

describe "Olson Zones", ->
    fullZoneLine = "Zone America/Chicago\t-5:50:36 -\tLMT\t1883 Nov 18 12:09:24"
    secondZoneLine = "\t\t\t-6:00\tUS\tC%sT\t1920"
    thirdZoneLine = "\t\t\t-6:00\tChicago\tC%sT\t1940"
    endZoneLine = "         -6:00   US  C%sT"
    reader = new OlsonReader

    processZone = (line, parentZone) ->
        reader.processZoneLine line, parentZone

    it "can process from full Zone lines with beginning having minimum date", ->
        zone = processZone fullZoneLine

        should?.exist zone?.range, "range"

        # Far enough for me
        beginYear = zone.range.begin.getUTCFullYear()
        
        # Moses time and what-not is far enough for me.
        beginYear.should.be.below -2000

    it "can process from full Zone lines with end time in standard time", ->
        zone = processZone fullZoneLine

        zone.range.end.should.equal helpers.Time.StandardTimeToUTC zone.offset, 1883, 10, 18, 12, 9, 24

    it "can process subsequent Zone lines", ->
        initialZone = processZone fullZoneLine

        secondZone = processZone secondZoneLine, initialZone

        secondZone.range.begin.should.equal initialZone.range.end, "1 -> 2 Zones"

        thirdZone = processZone thirdZoneLine, secondZone

        thirdZone.range.begin.should.equal secondZone.range.end, "2 -> 3 Zones"

        endZone = processZone endZoneLine, thirdZone

        endZone.range.begin.should.equal thirdZone.range.end, "3 -> 4 Zones"

        # Max Date
        endZone.range.end.getUTCFullYear().should.be.above 20000

    describe "Zone Sets", ->

        makeSet = (lines...) ->
            currZone = null
            zones = []
            for line in lines
                newZone = processZone line, currZone
                zones.push newZone
                currZone = newZone

            new OlsonZoneSet zones

        defaultSet = ->
            makeSet fullZoneLine, secondZoneLine, thirdZoneLine, endZoneLine

        it "can find an applicable zone by UTC date before the beginning of the zones records minimum date", ->
            zoneSet = defaultSet()
            
            firstZone = zoneSet.zones[0]

            earlyDate = firstZone.range.begin

            earlyDate = helpers.Days.AddToDate earlyDate, 100

            foundZone = zoneSet.findApplicable earlyDate

            should.exist foundZone

            foundZone.range.begin.getTime().should.be.below earlyDate.getTime()

            foundZone.should.equal firstZone

        it "can find an applicable zone by UTC date for a continuation zone", ->
            zoneSet = defaultSet()

            secondZone = zoneSet.zones[1]

            dt = helpers.Days.AddToDate secondZone.range.begin, 1

            foundZone = zoneSet.findApplicable dt

            should.exist foundZone

            foundZone.range.begin.getTime().should.be.below dt.getTime()

            foundZone.should.equal secondZone

        it "can find an applicable zone by UTC date for a future beyond continuations maximum date", ->
            zoneSet = defaultSet()

            lastZone = zoneSet.zones.slice(-1)[0]

            dt = helpers.Days.AddToDate lastZone.range.end, -1

            foundZone = zoneSet.findApplicable dt

            should.exist foundZone

            foundZone.range.end.getTime().should.be.above dt.getTime()

            foundZone.should.equal lastZone








        

