/*
 *  WallTime 0.2.0
 *  Copyright (c) 2013 Sprout Social, Inc.
 *  Available under the MIT License (http://bit.ly/walltime-license)
 */
 (function() {
  var init, req_TimeZoneTime, req_helpers, req_rule;

  init = function(helpers, rule, TimeZoneTime) {
    var Zone, ZoneSet, lib;
    Zone = (function() {
      function Zone(name, _offset, _rule, format, _until, currZone) {
        var begin, isNegative, offsetHours, offsetMins, offsetSecs, _ref;
        this.name = name;
        this._offset = _offset;
        this._rule = _rule;
        this.format = format;
        this._until = _until;
        _ref = helpers.Time.ParseGMTOffset(this._offset), isNegative = _ref[0], offsetHours = _ref[1], offsetMins = _ref[2], offsetSecs = _ref[3];
        this.offset = {
          negative: isNegative,
          hours: offsetHours,
          mins: offsetMins,
          secs: isNaN(offsetSecs) ? 0 : offsetSecs
        };
        begin = currZone ? helpers.Time.MakeDateFromTimeStamp(currZone.range.end.getTime() + 1) : helpers.Time.MinDate();
        this.range = {
          begin: begin,
          end: this._parseUntilDate(this._until)
        };
      }

      Zone.prototype._parseUntilDate = function(til) {
        var day, endTime, h, mi, month, monthName, neg, s, standardTime, time, year, _ref, _ref1;
        _ref = til.split(" "), year = _ref[0], monthName = _ref[1], day = _ref[2], time = _ref[3];
        _ref1 = time ? helpers.Time.ParseGMTOffset(time) : [false, 0, 0, 0], neg = _ref1[0], h = _ref1[1], mi = _ref1[2], s = _ref1[3];
        s = isNaN(s) ? 0 : s;
        if (!year || year === "") {
          return helpers.Time.MaxDate();
        }
        year = parseInt(year, 10);
        month = monthName ? helpers.Months.MonthIndex(monthName) : 0;
        day || (day = "1");
        if (helpers.Months.IsDayOfMonthRule(day)) {
          day = helpers.Months.DayOfMonthByRule(day, year, month);
        } else if (helpers.Months.IsLastDayOfMonthRule(day)) {
          day = helpers.Months.LastDayOfMonthRule(day, year, month);
        } else {
          day = parseInt(day, 10);
        }
        standardTime = helpers.Time.StandardTimeToUTC(this.offset, year, month, day, h, mi, s);
        endTime = helpers.Time.MakeDateFromTimeStamp(standardTime.getTime() - 1);
        return endTime;
      };

      Zone.prototype.updateEndForRules = function(getRulesNamed) {
        var endSave, hours, mins, rules, _ref;
        if (this._rule === "-" || this._rule === "") {
          return;
        }
        if (this._rule.indexOf(":") >= 0) {
          _ref = helpers.Time.ParseTime(this._rule), hours = _ref[0], mins = _ref[1];
          this.range.end = helpers.Time.ApplySave(this.range.end, {
            hours: hours,
            mins: mins
          });
        }
        rules = new rule.RuleSet(getRulesNamed(this._rule), this);
        endSave = rules.getYearEndDST(this.range.end);
        return this.range.end = helpers.Time.ApplySave(this.range.end, endSave);
      };

      Zone.prototype.UTCToWallTime = function(dt, getRulesNamed) {
        var hours, mins, rules, _ref;
        if (this._rule === "-" || this._rule === "") {
          return new TimeZoneTime(dt, this, helpers.noSave);
        }
        if (this._rule.indexOf(":") >= 0) {
          _ref = helpers.Time.ParseTime(this._rule), hours = _ref[0], mins = _ref[1];
          return new TimeZoneTime(dt, this, {
            hours: hours,
            mins: mins
          });
        }
        rules = new rule.RuleSet(getRulesNamed(this._rule), this);
        return rules.getWallTimeForUTC(dt);
      };

      Zone.prototype.WallTimeToUTC = function(dt, getRulesNamed) {
        var hours, mins, rules, _ref;
        if (this._rule === "-" || this._rule === "") {
          return helpers.Time.StandardTimeToUTC(this.offset, dt);
        }
        if (this._rule.indexOf(":") >= 0) {
          _ref = helpers.Time.ParseTime(this._rule), hours = _ref[0], mins = _ref[1];
          return helpers.Time.WallTimeToUTC(this.offset, {
            hours: hours,
            mins: mins
          }, dt);
        }
        rules = new rule.RuleSet(getRulesNamed(this._rule), this);
        return rules.getUTCForWallTime(dt, this.offset);
      };

      Zone.prototype.IsAmbiguous = function(dt, getRulesNamed) {
        var ambigCheck, hours, makeAmbigZone, mins, rules, utcDt, _ref, _ref1, _ref2;
        if (this._rule === "-" || this._rule === "") {
          return false;
        }
        if (this._rule.indexOf(":") >= 0) {
          utcDt = helpers.Time.StandardTimeToUTC(this.offset, dt);
          _ref = helpers.Time.ParseTime(this._rule), hours = _ref[0], mins = _ref[1];
          makeAmbigZone = function(begin) {
            var ambigZone, tmp;
            ambigZone = {
              begin: this.range.begin,
              end: helpers.Time.ApplySave(this.range.begin, {
                hours: hours,
                mins: mins
              })
            };
            if (ambigZone.end.getTime() < ambigZone.begin.getTime()) {
              tmp = ambigZone.begin;
              ambigZone.begin = ambigZone.end;
              ambigZone.end = tmp;
            }
            return ambigZone;
          };
          ambigCheck = makeAmbigZone(this.range.begin);
          if ((ambigCheck.begin.getTime() <= (_ref1 = utcDt.getTime()) && _ref1 < ambigCheck.end.getTime())) {
            return true;
          }
          ambigCheck = makeAmbigZone(this.range.end);
          (ambigCheck.begin.getTime() <= (_ref2 = utcDt.getTime()) && _ref2 < ambigCheck.end.getTime());
        }
        rules = new rule.RuleSet(getRulesNamed(this._rule), this);
        return rules.isAmbiguous(dt, this.offset);
      };

      return Zone;

    })();
    ZoneSet = (function() {
      function ZoneSet(zones, getRulesNamed) {
        var zone, _i, _len, _ref;
        this.zones = zones != null ? zones : [];
        this.getRulesNamed = getRulesNamed;
        if (this.zones.length > 0) {
          this.name = this.zones[0].name;
        } else {
          this.name = "";
        }
        _ref = this.zones;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          zone = _ref[_i];
          zone.updateEndForRules;
        }
      }

      ZoneSet.prototype.add = function(zone) {
        if (this.zones.length === 0 && this.name === "") {
          this.name = zone.name;
        }
        if (this.name !== zone.name) {
          throw new Error("Cannot add different named zones to a ZoneSet");
        }
        return this.zones.push(zone);
      };

      ZoneSet.prototype.findApplicable = function(dt, useOffset) {
        var findOffsetRange, found, range, ts, zone, _i, _len, _ref;
        if (useOffset == null) {
          useOffset = false;
        }
        ts = dt.getTime();
        findOffsetRange = function(zone) {
          return {
            begin: helpers.Time.UTCToStandardTime(zone.range.begin, zone.offset),
            end: helpers.Time.UTCToStandardTime(zone.range.end, zone.offset)
          };
        };
        found = null;
        _ref = this.zones;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          zone = _ref[_i];
          range = !useOffset ? zone.range : findOffsetRange(zone);
          if ((range.begin.getTime() <= ts && ts <= range.end.getTime())) {
            found = zone;
            break;
          }
        }
        return found;
      };

      ZoneSet.prototype.getWallTimeForUTC = function(dt) {
        var applicable;
        applicable = this.findApplicable(dt);
        if (!applicable) {
          return new TimeZoneTime(dt, helpers.noZone, helpers.noSave);
        }
        return applicable.UTCToWallTime(dt, this.getRulesNamed);
      };

      ZoneSet.prototype.getUTCForWallTime = function(dt) {
        var applicable;
        applicable = this.findApplicable(dt, true);
        if (!applicable) {
          return dt;
        }
        return applicable.WallTimeToUTC(dt, this.getRulesNamed);
      };

      ZoneSet.prototype.isAmbiguous = function(dt) {
        var applicable;
        applicable = this.findApplicable(dt, true);
        if (!applicable) {
          return false;
        }
        return applicable.IsAmbiguous(dt, this.getRulesNamed);
      };

      return ZoneSet;

    })();
    return lib = {
      Zone: Zone,
      ZoneSet: ZoneSet
    };
  };

  if (typeof window === 'undefined') {
    req_helpers = require("./helpers");
    req_rule = require("./rule");
    req_TimeZoneTime = require("./timezonetime");
    module.exports = init(req_helpers, req_rule, req_TimeZoneTime);
  } else if (typeof define !== 'undefined') {
    define(["olson/helpers", "olson/rule", "olson/timezonetime"], init);
  } else {
    this.WallTime || (this.WallTime = {});
    this.WallTime.zone = init(this.WallTime.helpers, this.WallTime.rule, this.WallTime.TimeZoneTime);
  }

}).call(this);
