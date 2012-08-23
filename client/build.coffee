requirejs = require "requirejs"
fs = require "fs"

# TODO: Load version number from package.json and put it in the file name?
pkg = JSON.parse fs.readFileSync('./package.json')

config =
    baseUrl: "./lib"
    name: "walltime"
    out: "./client/walltime.js"
    optimize: "none"


module.exports = 
    build: (callback, settings) ->
        for own key, val of settings
            config[key] = val

        requirejs.optimize config, (output) ->
            callback?(config.out, output)
