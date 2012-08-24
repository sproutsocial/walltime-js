
init = (zone) ->    

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
            @timeZoneName = name

        UTCToWallTime: (dt, zoneName = @timeZoneName) ->
            if !@zoneSet
                throw new Error "Must set the time zone before converting times"

            if zoneName != @timeZoneName
                @setTimeZone zoneName

            @zoneSet.getWallTimeForUTC dt

    # NOTE: Exporting an instantiated WallTime object.
    new WallTime

if typeof window == 'undefined'
    req_zone = require "./olson/zone"
    module.exports = init(req_zone)
else if typeof define != 'undefined'
    define ['olson/zone'], init
else
    @.WallTime or= {}

    # Some trickery here because we want a clean window.WallTime api,
    # But still have to keep the @.WallTime.helpers etc.
    api = init(@.WallTime.zone)
    for own key,val of @.WallTime
        api[key] = val

    @.WallTime = api

    # Check for and initialize with the passed in data.
    if @.WallTime.autoinit and @.WallTime.data?.rules and @.WallTime.data?.zoneSet
        @.WallTime.init @.WallTime.data.rules, @.WallTime.data.zones






