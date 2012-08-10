should = require "should"
OlsonReader = require "../lib/olson/reader"
OlsonCommon = require "../lib/olson/common"
OlsonZone = OlsonCommon.Zone
OlsonZoneSet = OlsonCommon.ZoneSet

describe "Olson Zones", ->
    fullZoneLine = "Zone America/Chicago\t-5:50:36 -\tLMT\t1883 Nov 18 12:09:24"
    secondZoneLine = "\t\t\t-6:00\tUS\tC%sT\t1920"
    thirdZoneLine = "\t\t\t-6:00\tChicago\tC%sT\t1940"
    reader = new OlsonReader

    it "can process from full Zone lines", ->
        zone = reader.processZoneLine fullZoneLine

        should?.exist zone?.range, "range"

        # Far enough for me
        zone.range.begin.getUTCFullYear().should.be.below 100

    it "can process subsequent Zone lines", ->
        initialZone = reader.processZoneLine fullZoneLine

        secondZone = reader.processZoneLine secondZoneLine, initialZone

        secondZone.range.begin.getUTCFullYear().should.equal initialZone.range.end.getUTCFullYear(), "1 -> 2 Year"

        thirdZone = reader.processZoneLine thirdZoneLine, secondZone

        thirdZone.range.begin.getUTCFullYear().should.equal secondZone.range.end.getUTCFullYear(), "2 -> 3 Year"

    describe "Zone Sets", ->




        

