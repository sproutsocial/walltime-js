
if typeof window == 'undefined'
    helpers = require "./helpers"

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

if typeof window == 'undefined'
    module.exports = TimeZoneTime
else
    define ["helpers"], "TimeZoneTime", TimeZoneTime
