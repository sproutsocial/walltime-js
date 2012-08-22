if typeof window == 'undefined'
    zone = require "./olson/zone"

class WallTime
    
    init: (rules = [], zones = []) ->
        @rules = rules
        @zones = zones
        @doneInit = true

    setTimeZone: (name) ->
        if !@doneInit
            throw new Error "Must call init with rules and zones before setting time zone"

        if !@zones[name]
            throw new Error "Unable to find time zone named #{name || '<blank>'}"

        matches = @zones[name]
        @zoneSet = new zone.ZoneSet(matches.zones, (ruleName) => @rules[ruleName])

    UTCToWallTime: (dt) ->
        if !@zoneSet
            throw new Error "Must set the time zone before converting times"

        @zoneSet.getWallTimeForUTC dt


if typeof window == 'undefined'
    module.exports = new WallTime
else
    define ['zone'], 'walltime', (zone) ->
        new WallTime



