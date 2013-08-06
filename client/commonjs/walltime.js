/*
 *  WallTime 0.2.0
 *  Copyright (c) 2013 Sprout Social, Inc.
 *  Available under the MIT License (http://bit.ly/walltime-license)
 */
 (function() {
  var api, init, key, req_help, req_rule, req_zone, val, _ref, _ref1, _ref2,
    __hasProp = {}.hasOwnProperty;

  init = function(helpers, rule, zone) {
    var WallTime;
    WallTime = (function() {
      function WallTime() {}

      WallTime.prototype.init = function(rules, zones) {
        if (rules == null) {
          rules = {};
        }
        if (zones == null) {
          zones = {};
        }
        this.zones = {};
        this.rules = {};
        this.addRulesZones(rules, zones);
        this.zoneSet = null;
        this.timeZoneName = null;
        return this.doneInit = true;
      };

      WallTime.prototype.addRulesZones = function(rules, zones) {
        var currZone, newRules, newZone, newZones, r, ruleName, ruleVals, z, zoneName, zoneVals, _i, _len, _results;
        if (rules == null) {
          rules = {};
        }
        if (zones == null) {
          zones = {};
        }
        currZone = null;
        for (zoneName in zones) {
          if (!__hasProp.call(zones, zoneName)) continue;
          zoneVals = zones[zoneName];
          newZones = [];
          currZone = null;
          for (_i = 0, _len = zoneVals.length; _i < _len; _i++) {
            z = zoneVals[_i];
            newZone = new zone.Zone(z.name, z._offset, z._rule, z.format, z._until, currZone);
            newZones.push(newZone);
            currZone = newZone;
          }
          this.zones[zoneName] = newZones;
        }
        _results = [];
        for (ruleName in rules) {
          if (!__hasProp.call(rules, ruleName)) continue;
          ruleVals = rules[ruleName];
          newRules = (function() {
            var _j, _len1, _results1;
            _results1 = [];
            for (_j = 0, _len1 = ruleVals.length; _j < _len1; _j++) {
              r = ruleVals[_j];
              _results1.push(new rule.Rule(r.name, r._from, r._to, r.type, r["in"], r.on, r.at, r._save, r.letter));
            }
            return _results1;
          })();
          _results.push(this.rules[ruleName] = newRules);
        }
        return _results;
      };

      WallTime.prototype.setTimeZone = function(name) {
        var matches,
          _this = this;
        if (!this.doneInit) {
          throw new Error("Must call init with rules and zones before setting time zone");
        }
        if (!this.zones[name]) {
          throw new Error("Unable to find time zone named " + (name || '<blank>'));
        }
        matches = this.zones[name];
        this.zoneSet = new zone.ZoneSet(matches, function(ruleName) {
          return _this.rules[ruleName];
        });
        return this.timeZoneName = name;
      };

      WallTime.prototype.Date = function(y, m, d, h, mi, s, ms) {
        if (m == null) {
          m = 0;
        }
        if (d == null) {
          d = 1;
        }
        if (h == null) {
          h = 0;
        }
        if (mi == null) {
          mi = 0;
        }
        if (s == null) {
          s = 0;
        }
        if (ms == null) {
          ms = 0;
        }
        y || (y = new Date().getUTCFullYear());
        return helpers.Time.MakeDateFromParts(y, m, d, h, mi, s, ms);
      };

      WallTime.prototype.UTCToWallTime = function(dt, zoneName) {
        if (zoneName == null) {
          zoneName = this.timeZoneName;
        }
        if (typeof dt === "number") {
          dt = new Date(dt);
        }
        if (zoneName !== this.timeZoneName) {
          this.setTimeZone(zoneName);
        }
        if (!this.zoneSet) {
          throw new Error("Must set the time zone before converting times");
        }
        return this.zoneSet.getWallTimeForUTC(dt);
      };

      WallTime.prototype.WallTimeToUTC = function(zoneName, y, m, d, h, mi, s, ms) {
        var wallTime;
        if (zoneName == null) {
          zoneName = this.timeZoneName;
        }
        if (m == null) {
          m = 0;
        }
        if (d == null) {
          d = 1;
        }
        if (h == null) {
          h = 0;
        }
        if (mi == null) {
          mi = 0;
        }
        if (s == null) {
          s = 0;
        }
        if (ms == null) {
          ms = 0;
        }
        if (zoneName !== this.timeZoneName) {
          this.setTimeZone(zoneName);
        }
        wallTime = typeof y === "number" ? helpers.Time.MakeDateFromParts(y, m, d, h, mi, s, ms) : y;
        return this.zoneSet.getUTCForWallTime(wallTime);
      };

      WallTime.prototype.IsAmbiguous = function(zoneName, y, m, d, h, mi) {
        var wallTime;
        if (zoneName == null) {
          zoneName = this.timeZoneName;
        }
        if (mi == null) {
          mi = 0;
        }
        if (zoneName !== this.timeZoneName) {
          this.setTimeZone(zoneName);
        }
        wallTime = typeof y === "number" ? helpers.Time.MakeDateFromParts(y, m, d, h, mi) : y;
        return this.zoneSet.isAmbiguous(wallTime);
      };

      return WallTime;

    })();
    return new WallTime;
  };

  if (typeof window === 'undefined') {
    req_zone = require("./olson/zone");
    req_rule = require("./olson/rule");
    req_help = require("./olson/helpers");
    module.exports = init(req_help, req_rule, req_zone);
  } else if (typeof define !== 'undefined') {
    if (!require.specified('walltime-data')) {
      if (typeof console !== "undefined" && console !== null) {
        if (typeof console.warn === "function") {
          console.warn("To use WallTime with requirejs please include the walltime-data.js script before requiring walltime");
        }
      }
      define('walltime-data', [], function() {
        return null;
      });
    }
    define(['olson/helpers', 'olson/rule', 'olson/zone', 'walltime-data'], function(dep_help, dep_rule, dep_zone, WallTimeData) {
      var lib;
      lib = init(dep_help, dep_rule, dep_zone);
      if (WallTimeData != null ? WallTimeData.zones : void 0) {
        lib.init(WallTimeData.rules, WallTimeData.zones);
      }
      return lib;
    });
  } else {
    this.WallTime || (this.WallTime = {});
    api = init(this.WallTime.helpers, this.WallTime.rule, this.WallTime.zone);
    _ref = this.WallTime;
    for (key in _ref) {
      if (!__hasProp.call(_ref, key)) continue;
      val = _ref[key];
      api[key] = val;
    }
    this.WallTime = api;
    if (this.WallTime.autoinit && ((_ref1 = this.WallTime.data) != null ? _ref1.rules : void 0) && ((_ref2 = this.WallTime.data) != null ? _ref2.zones : void 0)) {
      this.WallTime.init(this.WallTime.data.rules, this.WallTime.data.zones);
    }
  }

}).call(this);
