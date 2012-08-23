

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
        getTime: -> @wallTime.getTime()

    TimeZoneTime

if typeof window == 'undefined'
    req_helpers = require "./helpers"
    module.exports = init(req_helpers)
else if typeof define != 'undefined'
    define ["olson/helpers"], "TimeZoneTime", init
else
    @.WallTime = @.WallTime || {}
    @.WallTime.TimeZoneTime = init(@.WallTime.helpers)
