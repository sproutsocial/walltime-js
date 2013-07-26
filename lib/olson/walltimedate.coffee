

init = (helpers) ->
    
    class WallTimeDate extends Date
        constructor: (@utc, @zone, @save) ->
            @offset = @zone.offset
            @wallTime = helpers.Time.UTCToWallTime @utc, @offset, @save

        # Standard Date overrides
        getFullYear: -> @wallTime.getUTCFullYear()
        getMonth: -> @wallTime.getUTCMonth()
        getDate: -> @wallTime.getUTCDate()
        getDay: -> @wallTime.getUTCDay()
        getHours: -> @wallTime.getUTCHours()
        getMinutes: -> @wallTime.getUTCMinutes()
        getSeconds: -> @wallTime.getUTCSeconds()
        getMilliseconds: -> @wallTime.getUTCMilliseconds()
        
        # UTC Date overrides
        getUTCFullYear: -> @utc.getUTCFullYear()
        getUTCMonth: -> @utc.getUTCMonth()
        getUTCDate: -> @utc.getUTCDate()
        getUTCDay: -> @utc.getUTCDay()
        getUTCHours: -> @utc.getUTCHours()
        getUTCMinutes: -> @utc.getUTCMinutes()
        getUTCSeconds: -> @utc.getUTCSeconds()
        getUTCMilliseconds: -> @utc.getUTCMilliseconds()

        getTime: -> @utc.getTime()

        getTimezoneOffset: ->
            base = (@offset.hours * 60) + @offset.mins

            dst = (@save.hours * 60) + @save.mins

            unless @offset.negative
                base = -base

            base - dst

        toISOString: -> @utc.toISOString()
            
        toUTCString: -> @wallTime.toUTCString()

        toDateString: ->
            utcStr = @wallTime.toUTCString()
            caps = utcStr.match "([a-zA-Z]*), ([0-9]+) ([a-zA-Z]*) ([0-9]+)"
            [caps[1], caps[3], caps[2], caps[4]].join " "

        toFormattedTime: (use24HourTime = false) ->
            hour = origHour = @getHours()
            hour -= 12 if hour > 12 and !use24HourTime

            hour = 12 if hour == 0

            min = @getMinutes()
            min = "0" + min if min < 10

            meridiem = if origHour > 11 then ' PM' else ' AM'
            meridiem = '' if use24HourTime
            
            "#{hour}:#{min}#{meridiem}"

        setTime: (ms) ->
            @wallTime = helpers.Time.UTCToWallTime new Date(ms), @zone.offset, @save
            @_updateUTC()

        setFullYear: (y) ->
            @wallTime.setUTCFullYear y
            @_updateUTC()

        setMonth: (m) ->
            @wallTime.setUTCMonth m
            @_updateUTC()

        setDate: (utcDate) ->
            @wallTime.setUTCDate utcDate
            @_updateUTC()

        setHours: (hours) ->
            @wallTime.setUTCHours hours
            @_updateUTC()

        setMinutes: (m) ->
            @wallTime.setUTCMinutes m
            @_updateUTC()

        setSeconds: (s) ->
            @wallTime.setUTCSeconds s
            @_updateUTC()

        setMilliseconds: (ms) ->
            @wallTime.setUTCMilliseconds ms
            @_updateUTC()

        # Updates to
        _updateUTC: ->
            @utc = helpers.Time.WallTimeToUTC @offset, @save, @getFullYear(), @getMonth(), @getDate(), @getHours(), @getMinutes(), @getSeconds(), @getMilliseconds()

            @utc.getTime()

    TimeZoneTime

if typeof window == 'undefined'
    req_helpers = require "./helpers"
    module.exports = init(req_helpers)
else if typeof define != 'undefined'
    define ["olson/helpers"], init
else
    @WallTime or= {}
    @WallTime.WallTimeDate = init(@WallTime.helpers)
