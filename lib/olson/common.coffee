

class Rule
    constructor: (@name, @from, @to, @type, @in, @on, @at, @save, @letter) ->

class Zone
    constructor: (@name, @offset, @rules, @format, @until) ->


module.exports = 
    Rule: Rule
    Zone: Zone