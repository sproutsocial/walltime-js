fs            = require 'fs'
{print}       = require 'util'
{spawn, exec} = require 'child_process'
clientBuilder = require './client/build'

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


task 'build', ->
  build (fileName, list) -> 
    log "Success!", green
    log "Output to: #{fileName}"

task 'clean', ->
  removeCompiledFiles ->
    log "Success!"


