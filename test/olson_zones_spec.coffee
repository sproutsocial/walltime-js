should = require "should"
helpers = require "../lib/olson/helpers"
OlsonReader = require "../lib/olson/reader"
OlsonCommon = require "../lib/olson/common"
OlsonZone = OlsonCommon.Zone
OlsonZoneSet = OlsonCommon.ZoneSet

describe "Olson Zones", ->
    fullZoneLine = "Zone America/Chicago\t-5:50:36 -\tLMT\t1883 Nov 18 12:09:24"
    static1HourZoneLine = "\t\t\t-6:00\t1:00\tC%sT\t1920"
    secondZoneLine = "\t\t\t-6:00\tUS\tC%sT\t1920"
    thirdZoneLine = "\t\t\t-6:00\tChicago\tC%sT\t1940"
    endZoneLine = "         -6:00   US  C%sT"
    reader = new OlsonReader

    processZone = (line, parentZone) ->
        reader.processZoneLine line, parentZone

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

    makeZone = ->
        new OlsonZone("America/Chicago", "-5:50:36", "-", "LMT", "1883 Nov 18 12:09:24")

    makeRangeZone = ->
        new OlsonZone("America/Chihuahua", "-7:00:00", "-", "M%sT", "1998 Apr Sun>=1 3:00")

    makeLastRangeZone = ->
        new OlsonZone("Asia/Baku", "3:00", "RussiaAsia", "AZ%sT", "1992 Sep lastSat 23:00")

    makeReginaZone = ->
        new OlsonZone("America/Regina", "-7:00", "Regina", "M%sT", "1960 Apr lastSun 2:00")

    it "can set the begin and end range correctly for explicit end", ->
        zone = makeZone()

        expect = helpers.Time.MakeDateFromParts 1883, 10, 18, 12, 9, 24
        expect = helpers.Time.ApplyOffset expect, 
            negative: true
            hours: 5
            mins: 50
            secs: 36

        expect = helpers.Time.MakeDateFromTimeStamp(expect.getTime() - 1)

        zone.range.end.toUTCString().should.equal expect.toUTCString()

    it "can set the begin and end range correctly for end with range like Sun>=1", ->
        zone = makeRangeZone()

        expect = helpers.Time.MakeDateFromParts 1998, 3, 5, 3, 0
        expect = helpers.Time.ApplyOffset expect, 
            negative: true
            hours: 7
            mins: 0
            secs: 0

        expect = helpers.Time.MakeDateFromTimeStamp(expect.getTime() - 1)

        zone.range.end.toUTCString().should.equal expect.toUTCString()

    it "can set the begin and end range correctly for end with range like lastSat", ->
        zone = makeLastRangeZone()

        expect = helpers.Time.MakeDateFromParts 1992, 8, 26, 23, 0
        expect = helpers.Time.ApplyOffset expect, 
            negative: false
            hours: 3
            mins: 0
            secs: 0

        expect = helpers.Time.MakeDateFromTimeStamp(expect.getTime() - 1)

        zone.range.end.toUTCString().should.equal expect.toUTCString()

    it "can process America/Regina zones", ->
        zone = makeReginaZone()

        expect = helpers.Time.MakeDateFromParts 1960, 3, 24, 2, 0
        expect = helpers.Time.ApplyOffset expect, 
            negative: true
            hours: 7
            mins: 0
            secs: 0

        expect = helpers.Time.MakeDateFromTimeStamp(expect.getTime() - 1)

        zone.range.end.toUTCString().should.equal expect.toUTCString()


    it "can process from full Zone lines with beginning having minimum date", ->
        zone = processZone fullZoneLine

        should?.exist zone?.range, "range"

        # Far enough for me
        beginYear = zone.range.begin.getUTCFullYear()
        
        # Moses time and what-not is far enough for me.
        beginYear.should.be.below -2000

    it "can process subsequent Zone lines", ->
        initialZone = processZone fullZoneLine

        secondZone = processZone secondZoneLine, initialZone

        secondZone.range.begin.should.equal helpers.Time.MakeDateFromTimeStamp(initialZone.range.end.getTime() + 1), "1 -> 2 Zones"

        thirdZone = processZone thirdZoneLine, secondZone

        thirdZone.range.begin.should.equal helpers.Time.MakeDateFromTimeStamp(secondZone.range.end.getTime() + 1), "2 -> 3 Zones"

        endZone = processZone endZoneLine, thirdZone

        endZone.range.begin.should.equal helpers.Time.MakeDateFromTimeStamp(thirdZone.range.end.getTime() + 1), "3 -> 4 Zones"

        # Max Date
        endZone.range.end.getUTCFullYear().should.be.above 20000

    it "can convert a time to standard time when no rule is specified", ->
        zoneSet = defaultSet()

        firstZone = zoneSet.zones[0]

        firstZone._rule.should.equal "-"

        origTime = helpers.Time.MakeDateFromParts 1880, 0, 1

        standardTime = helpers.Time.UTCToStandardTime origTime, firstZone.offset

        resultTime = firstZone.UTCToWallTime origTime

        resultTime.wallTime.should.equal standardTime

    it "can convert a time to offset time when static offset rule is specified", ->
        zoneSet = makeSet fullZoneLine, static1HourZoneLine, endZoneLine

        staticZone = zoneSet.zones[1]

        staticZone._rule.should.equal "1:00"

        origTime = helpers.Time.MakeDateFromParts 1900, 0, 1

        standardTime = helpers.Time.UTCToStandardTime origTime, staticZone.offset

        offsetTime = helpers.Time.ApplySave standardTime, { hours: 1, mins: 0 }

        resultTime = staticZone.UTCToWallTime origTime

        resultTime.wallTime.should.equal offsetTime

    it "can convert a time to offset time when a named rule is specified", ->
        zoneSet = defaultSet()

        save = 
            hours: 1
            mins: 0

        namedRuleZone = zoneSet.zones[1]

        namedRuleZone._rule.should.equal "US"

        origTime = helpers.Time.MakeDateFromParts 1921, 0, 1

        standardTime = helpers.Time.UTCToStandardTime origTime, namedRuleZone.offset

        dstTime = helpers.Time.ApplySave standardTime, save

        getRules = (ruleName) ->
            ruleName.should.equal namedRuleZone._rule
            []

        resultTime = namedRuleZone.UTCToWallTime origTime, getRules

    describe "Zone Sets", ->

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








        

