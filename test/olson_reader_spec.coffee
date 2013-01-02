should = require "should"
fs = require "fs"

helpers = require "../lib/olson/helpers"
OlsonDownloader = require "../lib/olson/downloader"
OlsonReader = require "../lib/olson/reader"
Tokenizer = require "../lib/olson/reader/tokenizer"

describe "Olson Reader", ->
    testFilesPath = "./test/olsonfiles"
    ruleLine = "rule\tChicago\t1920\tonly\t-\tJun\t13\t2:00\t1:00\tD"
    maxRuleLine = "Rule\tUS\t2007\tmax\t-\tMar\tSun>=8\t2:00\t1:00\tD"
    zoneLine = "Zone America/Chicago\t-5:50:36 -\tLMT\t1883 Nov 18 12:09:24"
    zoneChildLine = "\t\t\t-6:00\tUS\tC%sT\t1920"


    resetFiles = ->
        return unless fs.existsSync testFilesPath

        files = fs.readdirSync testFilesPath
        fs.unlinkSync "#{testFilesPath}/#{file}" for file in files

        fs.rmdirSync testFilesPath

    it "has a reader", ->
        should.exist OlsonReader
    
    it "can parse Rule lines with comments at the end", ->
        reader = new OlsonReader
        checkRule = (r) ->
            r.name.should.equal "Chicago"
            r._from.should.equal "1920"
            r._to.should.equal "only"
            r.type.should.equal "-"
            r.in.should.equal "Jun"
            r.on.should.equal "13"
            r.at.should.equal "2:00"
            r.save.hours.should.equal 1
            r.save.mins.should.equal 0
            r.letter.should.equal "D"
        
        rule = reader.processRuleLine ruleLine
        checkRule rule

        rule = reader.processRuleLine(ruleLine + " # Some Comment")
        checkRule rule

    it "can parse Rule lines with 'max' To field", ->
        reader = new OlsonReader
        rule = reader.processRuleLine maxRuleLine
        offset = 
            negative: false
            hours: 0
            mins: 0
            secs: 0
        rule.forZone offset

        maxDt = helpers.Time.MaxDate()

        # That's far enough for me
        rule.toUTC.getUTCFullYear().should.above 20000

    it "can parse Zone lines with name and comments at the end", ->
        reader = new OlsonReader
        checkZone = (z) ->
            z.name.should.equal "America/Chicago", "name"
            z._offset.should.equal "-5:50:36", "offset"
            z._rule.should.equal "-", "rules"
            z.format.should.equal "LMT", "format"
            z._until.should.equal "1883 Nov 18 12:09:24", "til"

        zone = reader.processZoneLine zoneLine
        checkZone zone

        zone = reader.processZoneLine(zoneLine + " # Some Comment", null)
        checkZone zone

    it "can read America-Chicago test file", (done) ->
        reader = new OlsonReader

        reader.singleFile "./test/rsrc/America-Chicago", (result) ->
            should.exist result?.zones, "should have zones in result"
            should.exist result?.rules, "should have rules in result"

            chiZone = result.zones["America/Chicago"]

            should.exist chiZone, "should have America/Chicago zone in zones"

            chiZone.zones.length.should.be.above 1

            do done

    it "can read Olson files from a specific directory", (done) ->
        reader = new OlsonReader

        reader.directory "./test/rsrc", (result) ->
            should.exist result, "Should have returned a result"
            
            should.exist result["America-Chicago"], "Should have Chicago file"
            should.exist result["America-Chicago"].zones["America/Chicago"], "Should have Chicago zone in Chicago file"

            should.exist result["America-New_York"], "Should have New York file"
            should.exist result["America-New_York"].zones["America/New_York"], "Should have New York zone in New York file"

            do done

    it "allows you to specify which files should be read", (done) ->
        reader = new OlsonReader

        reader.allowedFiles = ["America-Chicago"]

        reader.directory "./test/rsrc", (result) ->
            should.exist result, "Should have returned a result"
            
            should.exist result["America-Chicago"], "Should have Chicago file"
            should.exist result["America-Chicago"].zones["America/Chicago"], "Should have Chicago zone in Chicago file"

            should.not.exist result["America-New_York"], "Should not have New York file"
            
            do done

    it "can read the northamerica Olson file", (done) ->
        reader = new OlsonReader

        reader.singleFile "./test/rsrc/full/northamerica", (result) ->
            should.exist result?.zones, "should have zones in result"
            should.exist result?.rules, "should have rules in result"

            chiZone = result.zones["America/Chicago"]

            should.exist chiZone, "should have America/Chicago zone in zones"

            # TODO: test other zone names

            chiZone.zones.length.should.be.above 1

            do done
    
    it "returns a list of all the read in TimeZones", -> 
        # We can combine them ourselves through the result that comes back from reader.directory, see time zone mapping test
        true

    it "can map time zone names to time zone files ('America/Chicago' -> 'northamerica')", (done) ->
        reader = new OlsonReader

        reader.directory "./test/rsrc", (result) ->
            should.exist result, "Should have returned a result"
            
            map = {}
            for own fileName, parsed of result
                for own zoneName, zoneSet of parsed.zones
                    map[zoneName] = fileName

            map["America/Chicago"].should.equal "America-Chicago"

            do done

    # Holding off on this until I see a need.
    # it "can build a list of specific TimeZones"

    describe "Line Tokenizer", ->
        t = new Tokenizer null, null
        it "can tokenize lines with no tabs", ->
            result = t.tokenize "Zone America/Chicago   -5:50:36 -  LMT 1883 Nov 18 12:09:24"

            should.exist result, "no result from tokenize"
            result.should.eql [ "Zone", "America/Chicago", "-5:50:36", "-", "LMT", "1883", "Nov", "18", "12:09:24" ]

        it "can tokenize with tabs", ->
            result = t.tokenize zoneLine

            should.exist result, "no result from tokenize"
            result.should.eql [ "Zone", "America/Chicago", "-5:50:36", "-", "LMT", "1883", "Nov", "18", "12:09:24" ]


