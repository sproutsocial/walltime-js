OlsonDownloader = require "./downloader"
OlsonReader = require "./reader"
{spawn, exec} = require 'child_process'

class OlsonFiles
    constructor: (@downloader = new OlsonDownloader, @reader = new OlsonReader) ->

    downloadTo: (filePath, next) ->
        @downloader.begin filePath, next

    readFrom: (filePath, next) ->
        @reader.directory filePath, next

    downloadAndRead: (filePath, next) ->
        console.log "This method is deprecated and will be removed in future versions; please use the git submodule of this project to load olson files"
        
        @downloadTo filePath, =>
            @readFrom filePath, (files) =>
                @_cleanFolder filePath, =>
                    next files

    _cleanFolder: (filePath, next) ->
        path = filePath.slice(0, -1) if filePath.slice(-1) == "/"
        rm = exec 'rm #{path}/*'
        rm.stdout.pipe process.stdout
        rm.stderr.pipe process.stderr
        rm.on 'exit', (status) -> next?()

module.exports = new OlsonFiles