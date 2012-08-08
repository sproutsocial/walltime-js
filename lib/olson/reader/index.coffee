fs = require "fs"
lineReader = require "line-reader"
OlsonCommon = require "../common"
Rule = OlsonCommon.Rule
Zone = OlsonCommon.Zone

class OlsonReader
    _isEmptyLine: (line) ->
        line.length < 1

    _trimComments: (str) ->
        return str unless str
        commentStart = str.indexOf "#"
        return str if commentStart < 0

        return (str.slice 0, commentStart).trimRight()

    # These are public for testing...
    processRuleLine: (line) ->
        # TODO: Parse Rule, return it.
        parts = line.split "\t"
        new Rule parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8], @_trimComments(parts[9])

    processZoneLine: (line, currZone) ->
        # TODO: Parse zone, return it.
        parts = line.split "\t"
        return null if parts.length < 4
        name = currZone
        if currZone == null
            name = parts[0].slice 5

        switch parts.length
            when 4
                offsetRulesParts = parts[1].split " "
                offset = offsetRulesParts[0]
                rules = offsetRulesParts[1]
                format = parts[2]
                til = parts[3]
            when 5
                offset = parts[1]
                rules = parts[2]
                format = parts[3]
                til = parts[4]
            when 6
                begin = 3
                offset = parts[begin]
                rules = parts[begin + 1]
                format = parts[begin + 2]
                til = parts[begin + 3]

        new Zone name, offset, rules, format, @_trimComments(til)

    singleFile: (filePath, next) ->
        rules = {}
        zones = {}
        inZone = null
        processLine = (curr, last) =>
            # Skip comments, empty lines
            if @_isEmptyLine(curr) || curr[0] == "#"
                return true

            # Rules always have RULE in front.
            if curr.slice(0, 4).toUpperCase() is "RULE"
                # Reset the current zone
                inZone = null
                
                # Process the rule
                rule = @processRuleLine curr
                # Add to the rules by name.
                rules[rule.name] = rules[rule.name] || []
                rules[rule.name].push rule
            else 
                zone = @processZoneLine curr, inZone
                if zone
                    inZone = zone.name
                    zones[zone.name] = zones[zone.name] or []
                    zones[zone.name].push zone

        fileDone = lineReader.eachLine filePath, processLine, "\n", "ascii"

        fileDone.then ->
            next
                rules: rules
                zones: zones

    directory: (dirPath, next) ->
        files = {}

        fs.readdir dirPath, (err, files) =>
            currFile = 0
            fileLength = files.length
            handleFinishedFile = (result) =>
                files[files[currFile]] = result
                currFile++
                return next files unless currFile < fileLength

                @singleFile "#{dirPath}/#{files[currFile]}", handleFinishedFile

            # Kick off the processing
            @singleFile "#{dirPath}/#{files[currFile]}", handleFinishedFile
             
                
module.exports = OlsonReader


