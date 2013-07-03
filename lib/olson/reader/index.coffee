fs = require "fs"
lineReader = require "line-reader"

OlsonCommon = require "../common"
Rule = OlsonCommon.Rule
Zone = OlsonCommon.Zone
ZoneSet = OlsonCommon.ZoneSet

Tokenizer = require "./tokenizer"

class OlsonReader
    constructor: ->
        @tokenizer = new Tokenizer
        @allowedFiles = null

    _isEmptyLine: (line) ->
        line.length < 1

    _trimComments: (str) ->
        return str unless str
        
        commentStart = str.indexOf "#"
        return str if commentStart < 0

        return (str.slice 0, commentStart).trimRight()

    # These are public for testing... Probably should make them their own classes or something
    processRuleLine: (line) ->
        # Parse Rule, return it.
        parts = @tokenizer.tokenize line
        new Rule parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8], @_trimComments(parts[9])

    processZoneLine: (line, currZone) ->
        # Parse zone, return it.
        parts = @tokenizer.tokenize line
        return null if parts.length < 3
        
        begin = 0
        if parts[0][0].toUpperCase() == "Z"
            # Has a leading Zone, should have at least 5 parts
            if parts.length < 5
                throw new Error "Unable to process short zone line: " + line

            begin = 2

        offset = parts[begin]
        rules = parts[begin + 1]
        format = parts[begin + 2]
        til = ""
        if parts.length > 3
            til = parts[begin + 3...].join(" ")

        # Use an existing name if present, or use the one from the parsed line
        name = if currZone then currZone.name else parts[1]

        new Zone name, offset, rules, format, @_trimComments(til), currZone

    _isNewZoneDeclaration: (line) ->
        line.slice(0, 4).toUpperCase() is "ZONE"

    singleFile: (filePath, next) ->
        rules = {}
        zones = {}
        inZone = null
        processLine = (curr, last) =>
            # Skip comments, empty lines
            if !curr or @_isEmptyLine(curr) or curr[0] == "#"
                return true

            firstFour = curr.slice(0, 4).toUpperCase()
            if firstFour is "LEAP" or firstFour is "LINK"
                # Not supported yet... v 2.0
                return true
            else if firstFour is "RULE"
                # Reset the current zone if this is a new rule declaration
                inZone = null
                rule = null
                
                # Process the rule
                rule = @processRuleLine curr

                # Add to the rules by name.
                rules[rule.name] = rules[rule.name] or []
                rules[rule.name].push rule
            else
                # Reset the current zone if this is a new zone declaration
                inZone = null if @_isNewZoneDeclaration curr
                zone = null

                zone = @processZoneLine curr, inZone
                if zone
                    inZone = zone
                    zones[zone.name] = zones[zone.name] or new ZoneSet
                    zones[zone.name].add zone

        # Need to not read any directories, will return undefined/null
        stat = fs.statSync filePath
        if stat?.isDirectory()
            return next()

        fileDone = lineReader.eachLine filePath, processLine, "\n", "utf8"

        fileDone.then ->
            next
                rules: rules
                zones: zones

    directory: (dirPath, next) ->
        results = {}

        fs.readdir dirPath, (err, dirFiles) =>
            throw err if err

            currFile = 0
            fileLength = dirFiles.length
            handleFinishedFile = (result) =>
                if result
                    results[dirFiles[currFile]] = result

                currFile++
                # Skip any not allowed files
                if @allowedFiles
                    while currFile < fileLength and dirFiles[currFile] not in @allowedFiles
                        currFile++

                # Bug out if out of files to read
                return next results unless currFile < fileLength

                @singleFile "#{dirPath}/#{dirFiles[currFile]}", handleFinishedFile

            # Skip any not allowed files
            if @allowedFiles
                while currFile < fileLength and dirFiles[currFile] not in @allowedFiles
                    currFile++
            
            # Bug out if out of files to read
            return next results unless currFile < fileLength

            # Kick off the processing
            @singleFile "#{dirPath}/#{dirFiles[currFile]}", handleFinishedFile
             
                
module.exports = OlsonReader


