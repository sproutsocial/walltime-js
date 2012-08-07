fs = require "fs"
path = require "path"
exec = (require "child_process").exec

# TODO: Move these classes to their own modules.

class WGetDownloader
    _downloadFiles: (filePath, next) ->
        # Run WGet to download files from FTP
        exec "wget --retr-symlinks -O '#{filePath}/tzdata-latest.tar.gz' 'ftp://ftp.iana.org/tz/tzdata-latest.tar.gz'", (err, out, stdErr) ->
            throw err if err
            do next
    _inflateFiles: (filePath, next) ->
        # Inflate the downloaded data file
        exec "gzip -dc '#{filePath}/tzdata-latest.tar.gz' | tar --directory '#{filePath}' -xf -", (err, out) ->
            throw err if err
            do next
    _removeZipFiles: (filePath, next) ->
        # Remove the old gzip files
        exec "rm '#{filePath}/tzdata-latest.tar.gz'", (err, out) ->
            throw err if err
            do next

    begin: (filePath, next) ->
        filePath = filePath.slice(0, -1) if filePath.slice(-1) == "/"
        remove = =>
            @_removeZipFiles filePath, next
        inflate = (after) =>
            @_inflateFiles filePath, after
        download = (after) =>
            @_downloadFiles filePath, after

        @_downloadFiles filePath, ->
            inflate ->
                do remove
        true

module.exports = WGetDownloader