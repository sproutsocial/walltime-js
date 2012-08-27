
init = (rule, zone) ->    

    class WallTime
        
        init: (rules = {}, zones = {}) ->
            
            @zones = {}
            currZone = null
            for own zoneName, zoneVals of zones
                newZones = []
                for z in zoneVals
                    newZone = new zone.Zone(z.name, z._offset, z._rule, z.format, z._until, currZone)
                    newZones.push newZone
                    currZone = newZone

                @zones[zoneName] = newZones

            @rules = {}
            for own ruleName, ruleVals of rules
                newRules = (new rule.Rule(r.name, r._from, r._to, r.type, r.in, r.on, r.at, r._save, r.letter) for r in ruleVals)
                @rules[ruleName] = newRules
            
            @doneInit = true

        setTimeZone: (name) ->
            if !@doneInit
                throw new Error "Must call init with rules and zones before setting time zone"

            if !@zones[name]
                throw new Error "Unable to find time zone named #{name || '<blank>'}"

            matches = @zones[name]
            @zoneSet = new zone.ZoneSet(matches, (ruleName) => @rules[ruleName])
            @timeZoneName = name

        UTCToWallTime: (dt, zoneName = @timeZoneName) ->
            if typeof dt == "number"
                dt = new Date(dt)

            if !@zoneSet
                throw new Error "Must set the time zone before converting times"

            if zoneName != @timeZoneName
                @setTimeZone zoneName

            @zoneSet.getWallTimeForUTC dt

    # NOTE: Exporting an instantiated WallTime object.
    new WallTime

if typeof window == 'undefined'
    req_zone = require "./olson/zone"
    req_rule = require "./olson/rule"
    module.exports = init(req_rule, req_zone)
else if typeof define != 'undefined'
    define ['olson/rule', 'olson/zone'], init
else
    @.WallTime or= {}

    # Some trickery here because we want a clean window.WallTime api,
    # But still have to keep the @.WallTime.helpers etc.
    api = init(@.WallTime.rule, @.WallTime.zone)
    for own key,val of @.WallTime
        api[key] = val

    @.WallTime = api

    # Check for and initialize with the passed in data.
    if @.WallTime.autoinit and @.WallTime.data?.rules and @.WallTime.data?.zones
        @.WallTime.init @.WallTime.data.rules, @.WallTime.data.zones






