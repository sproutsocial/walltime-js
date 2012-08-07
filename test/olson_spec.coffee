should = require "should"
fs = require "fs"
OlsonDownloader = require "../lib/olson/downloader"
OlsonReader = require "../lib/olson/reader"
olson = require "../lib/olson"

describe "Olson Files", ->
    describe "Downloader", ->
        testFilesPath = "./test/olsonfiles"
        resetFiles = ->
            return unless fs.existsSync testFilesPath

            files = fs.readdirSync testFilesPath
            fs.unlinkSync "#{testFilesPath}/#{file}" for file in files

            fs.rmdirSync testFilesPath

        beforeEach (next) ->
            do resetFiles
            # Create our test files directory
            fs.mkdirSync testFilesPath
            do next

        afterEach (next) ->
            # Reset all our files
            do resetFiles
            do next

        it "has a downloader", ->
            should.exist OlsonDownloader

        it "can download olson files to a specific directory", (next) ->
            @timeout 5000

            downloader = new OlsonDownloader
            downloader.begin testFilesPath, ->
                # Verify that the files were created
                files = fs.readdirSync testFilesPath
                files.length.should.be.above 1
                files.should.include "asia"
                files.should.include "northamerica"
                files.should.include "europe"
                do next

    describe "Reader", ->
        it "has a reader", ->
            should.exist OlsonReader
        it "can read olson files from a specific directory"
        it "returns a list of all the read in TimeZones"
        it "can map time zone names to time zone files ('America/Chicago' -> 'northamerica')"
        it "can build a list of specific TimeZones"