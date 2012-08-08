helpers = require "./helpers"
RuleLib = require "./rule"

# A Zone represents an Olson file line describing a steady state between two dates (or infinity for the last line of most zones)
# and either a static time offset or set of rules to apply to determine the offset from "Local Time"
class Zone
    constructor: (@name, @_offset, @rules, @format, @until) ->

        [offsetHours, offsetMins, offsetSecs] = helpers.Time.ParseGMTOffset @_offset
        @offset = 
            hours: offsetHours
            mins: offsetMins
            secs: if isNaN(offsetSecs) then 0 else offsetSecs

module.exports = 
    Days: helpers.Days
    Months: helpers.Months
    Rule: RuleLib.Rule
    RuleSet: RuleLib.RuleSet
    Zone: Zone