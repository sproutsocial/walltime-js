fs = require "fs"
path = require "path"
exec = (require "child_process").exec

# ANSI Terminal Colors
bold  = '\x1B[0;1m'
red   = '\x1B[0;31m'
green = '\x1B[0;32m'
reset = '\x1B[0m'

log = (message, color = green, explanation = '') ->
    console.log color + message + reset + ' ' + explanation

# The WGetDownloader will execute a series of shell commands to download and extract timezone files to a specific directory.
class WGetDownloader
    # Run WGet to download files from FTP
    _downloadFiles: (filePath, next) ->
        log "Downloading TzDb -> wget --retr-symlinks -O '#{filePath}/tzdata-latest.tar.gz' 'ftp://ftp.iana.org/tz/tzdata-latest.tar.gz'", bold
        exec "wget --retr-symlinks -O '#{filePath}/tzdata-latest.tar.gz' 'ftp://ftp.iana.org/tz/tzdata-latest.tar.gz'", (err, out, stdErr) ->
            throw Error err if err
            do next
    
    # Inflate the downloaded data file
    _inflateFiles: (filePath, next) ->
        exec "gzip -dc '#{filePath}/tzdata-latest.tar.gz' | tar --directory '#{filePath}' -xf -", (err, out) ->
            throw Error err if err
            do next
    # Remove the old gzip files and other files that come with the repo
    _removeZipFiles: (filePath, next) ->
        exec "rm '#{filePath}/tzdata-latest.tar.gz'", (err, out) ->
            throw Error err if err
            do next

    _removeCruftFiles: (filePath, next) ->
        ###
        # For some reason this is not seeing these files when run after _removeZipFiles.
        exec "rm \"#{filePath}/*.sh\" \"#{filePath}/*.tab\"", (err, out) ->
            throw Error err if err
            do next
        ###

        fs.unlink "#{filePath}/iso3166.tab", (err) ->
            throw err if err
            fs.unlink "#{filePath}/zone.tab", (err) ->
                throw err if err
                fs.unlink "#{filePath}/yearistype.sh", (err) ->
                    throw err if err
                    fs.unlink "#{filePath}/Makefile", (err) ->
                        throw err if err
                        do next


    # Start the downloading process to the specified directory.
    # *NOTE*: The supplied file path should be an empty directory because we will remove files in an attempt to clean up.
    begin: (filePath, next) ->
        filePath = filePath.slice(0, -1) if filePath.slice(-1) == "/"
        remove = =>
            @_removeZipFiles filePath, =>
                @_removeCruftFiles filePath, next
        inflate = (after) =>
            @_inflateFiles filePath, after
                
        download = (after) =>
            @_downloadFiles filePath, after

        @_downloadFiles filePath, ->
            inflate ->
                do remove
        
        true

module.exports = WGetDownloader