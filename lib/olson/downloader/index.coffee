fs = require "fs"
path = require "path"
exec = (require "child_process").exec


# The WGetDownloader will execute a series of shell commands to download and extract timezone files to a specific directory.
class WGetDownloader
    # Run WGet to download files from FTP
    _downloadFiles: (filePath, next) ->
        exec "wget --retr-symlinks -O '#{filePath}/tzdata-latest.tar.gz' 'ftp://ftp.iana.org/tz/tzdata-latest.tar.gz'", (err, out, stdErr) ->
            throw err if err
            do next
    # Inflate the downloaded data file
    _inflateFiles: (filePath, next) ->
        exec "gzip -dc '#{filePath}/tzdata-latest.tar.gz' | tar --directory '#{filePath}' -xf -", (err, out) ->
            throw err if err
            do next
    # Remove the old gzip files and other files that come with the 
    _removeZipFiles: (filePath, next) ->
        exec "rm '#{filePath}/tzdata-latest.tar.gz'", (err, out) ->
            throw err if err
            do next
    # Start the downloading process to the specified directory.  
    # *NOTE*: The supplied file path should be an empty directory because we will remove files in an attempt to clean up.
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