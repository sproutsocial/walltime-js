fs            = require 'fs'
{print}       = require 'util'
{spawn, exec} = require 'child_process'
uglifyJS = require "uglify-js"
clientBuilder = require './client/build'
olsonFiles = require "./lib/olson"

# ANSI Terminal Colors
bold  = '\x1B[0;1m'
red   = '\x1B[0;31m'
green = '\x1B[0;32m'
reset = '\x1B[0m'

pkg = JSON.parse fs.readFileSync('./package.json')
testCmd = pkg.scripts.test
  

log = (message, color = green, explanation = '') ->
  console.log color + message + reset + ' ' + explanation

clientFiles = ['./lib/walltime', './lib/olson/helpers', './lib/olson/timezonetime', './lib/olson/rule', './lib/olson/zone']

# Compiles necessary client side files for requireJS optimizer
compileCoffeeFiles = (callback) ->
  options = ['-c'].concat(clientFiles)
  coffee = spawn 'coffee', options
  coffee.stdout.pipe process.stdout
  coffee.stderr.pipe process.stderr
  coffee.on 'exit', (status) -> callback?()

removeCompiledFiles = (callback) ->
  rm = exec 'rm ./lib/*.js ./lib/olson/*.js ./lib/olson/downloader/*.js ./lib/olson/reader/*.js'
  rm.stdout.pipe process.stdout
  rm.stderr.pipe process.stderr
  rm.on 'exit', (status) -> callback?()

minifyJSFile = (filePath, callback) ->
  fs.readFile filePath, "utf-8", (err, contents) ->
    throw err if err

    jsp = uglifyJS.parser
    pro = uglifyJS.uglify
    
    ast = jsp.parse contents.toString() # parse code and get the initial AST
    ast = pro.ast_mangle ast # get a new AST with mangled names
    ast = pro.ast_squeeze ast # get an AST with compression optimizations
    final_code = pro.gen_code ast # compressed code here

    # Write the file out with a .min.js extension
    minFileName = filePath.replace ".js", ".min.js"
    fs.writeFile minFileName, final_code, (ierr) ->
      throw ierr if ierr

      callback?(minFileName)


build = (callback) ->
  compileCoffeeFiles ->
    clientBuilder.build (fileName, fileList) ->
      minifyJSFile fileName, (minFileName) ->
        removeCompiledFiles ->
          callback?(fileName, minFileName, fileList)

# mocha test
test = (callback) ->
  options = [
    '--compilers'
    'coffee:coffee-script'
    '--colors'
    '--require'
    'should'
  ]
  spec = spawn 'mocha', options
  spec.stdout.pipe process.stdout 
  spec.stderr.pipe process.stderr
  spec.on 'exit', (status) -> callback?() if status is 0


task 'build', 'Build the client side walltime.js library', ->
  build (fileName, minFileName, list) -> 
    log "Success!", green
    log "Output to: #{fileName} and #{minFileName}"

option "-f", "--filename [OLSON_FILE_NAME*]", "Specify which specific OLSON files to parse"
option "-z", "--zonename [OLSON_ZONE_NAME*]", "Specify a specific zone to include"
option "-i", "--olsonfiles [OLSON_FILE_LOCATION]", "Specify the olson file location"
option "-o", "--outputname [FILE_NAME]", "Specify the output file name"

buildDataFile = (opts, callback) ->
  opts.filename or= []
  opts.zonename or= []
  opts.outputname or= "./client/walltime-data.js"

  allFiles = true
  filesToProcess = {}
  if opts.filename.length != 0
    allFiles = false
    # Set a lookup of what file names where passed in from the options
    filesToProcess[name] = true for name in opts.filename

    log "Processing: " + opts.filename.join(",")
  else
    log "Processing All Files", bold

  allZones = true
  zonesToProcess = {}
  if opts.zonename.length != 0
    allZones = false
    # Set a lookup of what zones to process
    zonesToProcess[name] = true for name in opts.zonename

    log "Processing zones: " + opts.zonename.join(",")
  else
    log "Processing All Zones", bold

  processOlsonFiles = (files) ->
    # Aggregate up the rules and zones from each file.
    rules = {}
    zones = {}
    # For each parsed file that we want to build data for
    for own fileName, rulesZones of files when allFiles or filesToProcess[fileName]
      # Add the zones to our existing zones
      for own zoneName, zoneVals of rulesZones.zones
        zones[zoneName] or= []
        zones[zoneName].push.apply zones[zoneName], zoneVals.zones

      # Add the rules to our existing rules
      for own ruleName, ruleVals of rulesZones.rules
        rules[ruleName] or= []
        rules[ruleName].push.apply rules[ruleName], ruleVals
      
      log "Processed File: ", green, fileName

    # If we aren't processing all zones, clean up our rules and zones
    if !allZones
      newZones = {}
      newRules = {}
      for own zoneName, zoneVals of zones when zonesToProcess[zoneName]
        console.log "Processing #{zoneName}"
        for zone in zoneVals when zone._rule != "-" and zone._rule != "" and rules[zone._rule] and !newRules[zone._rule]
          console.log "Adding Rule: #{zone._rule}"
          newRules[zone._rule] or= rules[zone._rule]
        newZones[zoneName] = zoneVals

      rules = newRules
      zones = newZones

    # Output a client side data include file

    # Wrapped in a closure, use existing WallTime object if present, export to WallTime.data
    output = "(function() {\n
      window.WallTime || (window.WallTime = {});\n
      window.WallTime.data = {\n
        rules: #{JSON.stringify(rules)},\n
        zones: #{JSON.stringify(zones)}\n
      };\n
      window.WallTime.autoinit = true;\n
}).call(this);"

    outFile = opts.outputname
    fs.writeFile outFile, output, (err) ->
      throw err if err
      minifyJSFile outFile, (minFileName) ->
        log "Success!", green, "- Files written to: #{outFile} and #{minFileName}"
        callback?()

  
  if opts.olsonfiles
    olsonFiles.readFrom opts.olsonfiles, processOlsonFiles
  else
    olsonFiles.downloadAndRead "./client/olson", processOlsonFiles

task 'data', "Build the client side olson data package (defaults to all timezone files and all zones)", (opts) ->
  buildDataFile opts

task 'individual', ->
  olsonFilePath = "./client/olson"
  slashRegex = new RegExp "\/", "g"
  spaceRegex = new RegExp " ", "g"
  olsonFiles.downloadAndRead olsonFilePath, (files) ->
    fileOpts = []
    for own fileName, rulesZones of files
      for own zoneName, zoneVals of rulesZones.zones
        nameSafe = zoneName.replace(slashRegex, "-").replace(spaceRegex, "_")
        fileOpts.push
          olsonfiles: olsonFilePath
          filename: [fileName]
          zonename: [zoneName]
          outputname: "./client/individual/walltime-data[#{nameSafe}].js"

    currFile = 0
    processFile = () ->
      if currFile >= fileOpts.length
        log "All done!", green, "#{currFile+1} files created"
        return

      buildDataFile fileOpts[currFile++], processFile

    processFile()


task 'clean', ->
  removeCompiledFiles ->
    log "Success!"
