fs            = require 'fs'
{print}       = require 'util'
{spawn, exec} = require 'child_process'
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

build = (callback) ->
  compileCoffeeFiles ->
    clientBuilder.build (fileName, fileList) ->
      removeCompiledFiles ->
        callback?(fileName, fileList)

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
  build (fileName, list) -> 
    log "Success!", green
    log "Output to: #{fileName}"

option "-f", "--filename [OLSON_FILE_NAME*]", "Specify which specific OLSON files to parse"

task 'data', "Build the client side olson data package (defaults to all timezone files)", (opts) ->
  opts.filename or= []

  allFiles = true
  filesToProcess = {}
  if opts.filename.length != 0
    allFiles = false
    # Set a lookup of what file names where passed in from the options
    filesToProcess[name] = true for name in opts.filename

    log "Processing: " + opts.filename.join(",")
  else
    log "Processing All Files", bold

  olsonFiles.downloadAndRead "./client/olson", (files) ->
    # Aggregate up the rules and zones from each file.
    rules = {}
    zones = {}
    # For each parsed file that we want to build data for
    for own fileName, rulesZones of files 
      continue if !allFiles and !filesToProcess[fileName]
      log "Processed File: ", green, fileName
      # Add the rules to our existing rules
      for own ruleName, ruleVals of rulesZones.rules
        rules[ruleName] or= []
        rules[ruleName].push.apply rules[ruleName], ruleVals
      # Add the zones to our existing zones
      for own zoneName, zoneVals of rulesZones.zones
        zones[zoneName] or= []
        zones[zoneName].push.apply zones[zoneName], zoneVals

    # Output a client side data include file

    # Wrapped in a closure, use existing WallTime object if present, export to WallTime.data
    output = "(function() {\n
      window.WallTime = window.WallTime || {};\n
      window.WallTime.data = {\n
        rules: #{JSON.stringify(rules)},\n
        zones: #{JSON.stringify(zones)}\n
      };\n
      window.WallTime.autoinit = true;\n
}).call(this);"

    outFile = "./client/walltime-data.js"
    fs.writeFile outFile, output, (err) ->
      log "Success!", green, "- File written to: #{outFile}"

task 'clean', ->
  removeCompiledFiles ->
    log "Success!"
