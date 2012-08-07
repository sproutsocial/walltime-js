OlsonDownloader = require "./downloader"
OlsonReader = require "./reader"

class OlsonFiles
    constructor: (@downloader = new OlsonDownloader) ->

    downloadTo: (filePath, next) ->
        @downloader.begin filePath, next

module.exports = new OlsonFiles