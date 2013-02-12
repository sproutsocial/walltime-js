

init = (helpers) ->
    
    class TimeZoneTime
        constructor: (@utc, @zone, @save) ->
            @offset = @zone.offset        
            @wallTime = helpers.Time.UTCToWallTime @utc, @zone.offset, @save

        # Standard Date overrides
        getFullYear: -> @wallTime.getUTCFullYear()
        getMonth: -> @wallTime.getUTCMonth()
        getDate: -> @wallTime.getUTCDate()
        getDay: -> @wallTime.getUTCDay()
        getHours: -> @wallTime.getUTCHours()
        getMinutes: -> @wallTime.getUTCMinutes()
        getSeconds: -> @wallTime.getUTCSeconds()
        getMilliseconds: -> @wallTime.getUTCMilliseconds()
        getTime: -> @utc.getTime()

        toDateString: ->
            utcStr = @wallTime.toUTCString()
            caps = utcStr.match "([a-zA-Z]*), ([0-9]+) ([a-zA-Z]*) ([0-9]+)"
            [caps[1], caps[3], caps[2], caps[4]].join " "

        toFormattedTime: (use24HourTime = false) ->
            hour = @getHours()
            min = @getMinutes()

            meridiem = if hour > 11 then 'PM' else 'AM'

            if (min < 10) then min = "0" + min
            if hour > 12 and !use24HourTime then hour -= 12
            if hour == 0 then hour = 12

            return if use24HourTime
            then hour + ':' + min
            else hour + ':' + min + ' ' + meridiem

        setHours: (h, mi, s, ms) -> @wallTime.setUTCHours(h, mi, s, ms)

    TimeZoneTime

if typeof window == 'undefined'
    req_helpers = require "./helpers"
    module.exports = init(req_helpers)
else if typeof define != 'undefined'
    define ["olson/helpers"], "timezonetime", init
else
    @.WallTime or= {}
    @.WallTime.TimeZoneTime = init(@.WallTime.helpers)
