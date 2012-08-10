strscan = require "strscan"

Regexes =
    words: /\"?([\w\-\+\:/\\/\(\)%#>=]+)\"?/
    spaces: /\s+/

class WhiteSpaceLineTokenizer
    constructor: (@wordRegEx = Regexes.words, @spaceRegEx = Regexes.spaces) ->

    tokenize: (line) ->
        # Skip any leading whitespace
        scanner = new strscan.StringScanner line.trimLeft()
        result = []

        stuck = 0

        while not scanner.hasTerminated()
            currMatch = (scanner.scan @wordRegEx)
            # Skip this if no word match
            if not currMatch
                stuck++

                if stuck > 2
                    throw new Error "Stuck during tokenizing: " + line
                continue

            # Don't process the rest if there is a comment
            break if currMatch[0] is "#"

            result.push currMatch

            # Skip any spaces to the next word
            scanner.scan @spaceRegEx

            stuck = 0

        result

module.exports = WhiteSpaceLineTokenizer