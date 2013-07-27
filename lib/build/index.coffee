# This is left over stragglers from the original cakefile build process

fs = require 'fs'
path = require 'path'

uglifyJS = require "uglify-js"
grunt = require "grunt"
_ = grunt.util._

olsonFiles = require "../olson"

# Allowed olson files
allowedFiles = [
  'africa'
  'antarctica'
  'asia'
  'australasia'
  'backward'
  'etcetera'
  'europe'
  'factory'
  'leapseconds'
  'northamerica'
  'pacificnew'
  'solar87'
  'solar88'
  'solar89'
  'southamerica'
  'systemv'
]

# Helper log function left over from Cakefile
log = -> grunt.log.writeln.apply grunt.log, arguments

minifyJSFile = (filePath, done) ->
    contents = grunt.file.read filePath
      
    jsp = uglifyJS.parser
    pro = uglifyJS.uglify
    
    ast = jsp.parse contents.toString() # parse code and get the initial AST
    ast = pro.ast_mangle ast # get a new AST with mangled names
    ast = pro.ast_squeeze ast # get an AST with compression optimizations
    final_code = pro.gen_code ast # compressed code here

    # Write the file out with a .min.js extension
    minFileName = filePath.replace ".js", ".min.js"
    grunt.file.write minFileName, final_code

    done?(minFileName)

# Build a walltime-data file from options
buildDataFile = (opts, done) ->
    opts.filename or= []
    opts.zonename or= []
    opts.outputname or= path.join(process.cwd(), "client/walltime-data.js")
    opts.minyear = parseInt opts.minyear || "-271822", 10

    dataFileTemplate = grunt.file.read("lib/build/dataFile.tpl")
    
    allFiles = true
    filesToProcess = {}
    fileDescription = "[All Files]"
    if opts.filename.length != 0
        allFiles = false
        # Set a lookup of what file names were passed in from the options
        filesToProcess[name] = true for name in opts.filename

        fileDescription = "[#{opts.filename.join(",")}]"

    allZones = true
    zonesToProcess = {}
    zoneDescription = "[All Zones]"
    if opts.zonename.length != 0
        allZones = false
        # Set a lookup of what zones to process
        zonesToProcess[name] = true for name in opts.zonename

        zoneDescription = "[#{opts.zonename.join(",")}]"

    grunt.log.writeln("Processing #{fileDescription} >> #{zoneDescription}")

    processOlsonFiles = (files) ->
        # Aggregate up the rules and zones from each file.
        rules = {}
        zones = {}
        # For each parsed file that we want to build data for
        for own fileName, rulesZones of files
            continue unless allFiles or filesToProcess[fileName]
            
            # Skip the indices if files is an array
            continue unless isNaN(parseInt(fileName, 10))

            # Add the zones to our existing zones
            for own zoneName, zoneVals of rulesZones.zones
                zones[zoneName] or= []
                saveZones = []
                for z in zoneVals.zones
                    
                    if z.range.end.getFullYear() >= opts.minyear
                        saveZones.push z
                    else
                        grunt.log.writeln "Filtered zone #{z.name}: ".yellow, "#{z.range.end.getFullYear()}"

                    # Remove extra fields from zones
                    delete z.range
                    delete z.offset
                
                zones[zoneName].push.apply zones[zoneName], saveZones

            # Add the rules to our existing rules
            for own ruleName, ruleVals of rulesZones.rules
                rules[ruleName] or= []
                saveVals = []
                for r in ruleVals
                    if r.to >= opts.minyear
                        saveVals.push(r)
                    else
                        grunt.log.writeln "Filtered rule #{ruleName}: ".yellow, "#{r.to}"
                    # Remove extra fields from rules
                    delete r.from
                    delete r.to
                    delete r.save
                    delete r.isMax
                rules[ruleName].push.apply rules[ruleName], saveVals
        
        # If we aren't processing all zones, clean up our rules and zones
        if !allZones
            newZones = {}
            newRules = {}
            for own zoneName, zoneVals of zones when zonesToProcess[zoneName]
                for zone in zoneVals when zone._rule != "-" and zone._rule != "" and rules[zone._rule] and !newRules[zone._rule]
                    newRules[zone._rule] or= rules[zone._rule]
                newZones[zoneName] = zoneVals

            rules = newRules
            zones = newZones

        # Output a client side data include file
        output = grunt.template.process(dataFileTemplate, { data: { name: path.basename(opts.outputname), rules: JSON.stringify(rules), zones: JSON.stringify(zones)} })

        outFile = opts.outputname
        grunt.file.write outFile, output
        grunt.log.write("Creating #{outFile}...").ok()
        
        minifyJSFile outFile, (minFileName) ->
            grunt.log.write("Creating #{minFileName}...").ok()
            done?()

    # Set the allowed files to process so we have more control over what comes in.
    olsonFiles.reader.allowedFiles = allowedFiles
    
    olsonFiles.readFrom "./client/olson", processOlsonFiles

buildIndividualFile = (opts, done) ->
    opts.format or= "walltime-data[%s]"
    olsonFilePath = path.join(process.cwd(), "/client/olson/")
    slashRegex = new RegExp "\/", "g"
    spaceRegex = new RegExp " ", "g"

    processFiles = (files) ->
        fileOpts = []
        for own fileName, rulesZones of files
            for own zoneName, zoneVals of rulesZones.zones
                nameSafe = zoneName.replace(slashRegex, "-").replace(spaceRegex, "+")
                outputName = opts.format.replace("%s", nameSafe)
                fileOpts.push
                    olsonfiles: olsonFilePath
                    filename: [fileName]
                    zonename: [zoneName]
                    minyear: opts.minyear
                    outputname: "./client/individual/#{outputName}.js"

        currFile = 0
        processFile = ->
            if currFile >= fileOpts.length
                log "All done!".green, "#{currFile+1} files created"
                return done?()

            buildDataFile fileOpts[currFile++], processFile

        processFile()

    olsonFiles.reader.allowedFiles = allowedFiles
    olsonFiles.readFrom olsonFilePath, processFiles

module.exports =
    allowedFiles: allowedFiles
    
    buildDataFile: buildDataFile

    buildIndividualFile: buildIndividualFile

    registerGruntTask: (grunt) ->
        grunt.registerMultiTask "walltime-data", "Build a walltime data file", ->
            fn = grunt.option("filename")?.split(",") || []
            zn = grunt.option("zonename")?.split(",") || []

            opts = this.options({
                filename: fn
                zonename: zn
                outputname: grunt.option("outputname")
                minyear: grunt.option("minyear")
            })

            done = this.async()

            buildDataFile opts, done

        grunt.registerMultiTask "walltime-individual", "Build individual data file(s)", ->
            opts = this.options({
                format: grunt.option("format")
            })

            done = this.async()

            buildIndividualFile opts, done

        grunt.registerMultiTask "walltime-verify", "Verify data files have zones and rules", ->

            opts = this.options({
                allowEmptyRules: true
                allowEmptyZones: false
            })

            this.filesSrc.forEach (filepath) ->
                fileData = require path.join(process.cwd(), filepath)
                
                grunt.log.write("#{filepath}...")
                unless fileData?
                    grunt.log.error()
                    return grunt.warn("Unable to find WallTime.data")

                unless opts.allowEmptyRules or _.keys(fileData.rules).length > 0
                    grunt.log.error()
                    return grunt.warn("Unable to find any rules")

                unless opts.allowEmptyZones or _.keys(fileData.zones).length > 0
                    grunt.log.error()
                    return grunt.warn("Unable to find any zones")

                grunt.log.ok()

