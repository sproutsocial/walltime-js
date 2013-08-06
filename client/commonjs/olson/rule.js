/*
 *  WallTime 0.2.0
 *  Copyright (c) 2013 Sprout Social, Inc.
 *  Available under the MIT License (http://bit.ly/walltime-license)
 */
 (function() {
  var init, req_TimeZoneTime, req_helpers,
    __hasProp = {}.hasOwnProperty;

  init = function(helpers, TimeZoneTime) {
    var CompareOnFieldHandler, LastOnFieldHandler, NumberOnFieldHandler, Rule, RuleSet, lib;
    NumberOnFieldHandler = (function() {
      function NumberOnFieldHandler() {}

      NumberOnFieldHandler.prototype.applies = function(str) {
        return !isNaN(parseInt(str, 10));
      };

      NumberOnFieldHandler.prototype.parseDate = function(str) {
        return parseInt(str, 10);
      };

      return NumberOnFieldHandler;

    })();
    LastOnFieldHandler = (function() {
      function LastOnFieldHandler() {}

      LastOnFieldHandler.prototype.applies = helpers.Months.IsLastDayOfMonthRule;

      LastOnFieldHandler.prototype.parseDate = function(str, year, month, qualifier, gmtOffset, daylightOffset) {
        return helpers.Months.LastDayOfMonthRule(str, year, month);
      };

      return LastOnFieldHandler;

    })();
    CompareOnFieldHandler = (function() {
      function CompareOnFieldHandler() {}

      CompareOnFieldHandler.prototype.applies = helpers.Months.IsDayOfMonthRule;

      CompareOnFieldHandler.prototype.parseDate = function(str, year, month) {
        return helpers.Months.DayOfMonthByRule(str, year, month);
      };

      return CompareOnFieldHandler;

    })();
    Rule = (function() {
      function Rule(name, _from, _to, type, _in, on, at, _save, letter) {
        var saveHour, saveMinute, toYear, _ref;
        this.name = name;
        this._from = _from;
        this._to = _to;
        this.type = type;
        this["in"] = _in;
        this.on = on;
        this.at = at;
        this._save = _save;
        this.letter = letter;
        this.from = parseInt(this._from, 10);
        this.isMax = false;
        toYear = this.from;
        switch (this._to) {
          case "max":
            toYear = (helpers.Time.MaxDate()).getUTCFullYear();
            this.isMax = true;
            break;
          case "only":
            toYear = this.from;
            break;
          default:
            toYear = parseInt(this._to, 10);
        }
        this.to = toYear;
        _ref = this._parseTime(this._save), saveHour = _ref[0], saveMinute = _ref[1];
        this.save = {
          hours: saveHour,
          mins: saveMinute
        };
      }

      Rule.prototype.forZone = function(offset) {
        this.offset = offset;
        this.fromUTC = helpers.Time.MakeDateFromParts(this.from, 0, 1, 0, 0, 0);
        this.fromUTC = helpers.Time.ApplyOffset(this.fromUTC, offset);
        this.toUTC = helpers.Time.MakeDateFromParts(this.to, 11, 31, 23, 59, 59, 999);
        return this.toUTC = helpers.Time.ApplyOffset(this.toUTC, offset);
      };

      Rule.prototype.setOnUTC = function(year, offset, getPrevSave) {
        var atQualifier, onParsed, toDay, toHour, toMinute, toMonth, _ref,
          _this = this;
        toMonth = helpers.Months.MonthIndex(this["in"]);
        onParsed = parseInt(this.on, 10);
        toDay = !isNaN(onParsed) ? onParsed : this._parseOnDay(this.on, year, toMonth);
        _ref = this._parseTime(this.at), toHour = _ref[0], toMinute = _ref[1], atQualifier = _ref[2];
        this.onUTC = helpers.Time.MakeDateFromParts(year, toMonth, toDay, toHour, toMinute);
        this.onUTC.setUTCMilliseconds(this.onUTC.getUTCMilliseconds() - 1);
        this.atQualifier = atQualifier !== '' ? atQualifier : "w";
        this.onUTC = helpers.Time.QualifiedTimeToUTC(this.onUTC, this.atQualifier, offset, function() {
          return getPrevSave(_this);
        });
        return this.onSort = "" + toMonth + "-" + toDay + "-" + (this.onUTC.getUTCHours()) + "-" + (this.onUTC.getUTCMinutes());
      };

      Rule.prototype.appliesToUTC = function(dt) {
        return (this.fromUTC <= dt && dt <= this.toUTC);
      };

      Rule.prototype._parseOnDay = function(onStr, year, month) {
        var handler, handlers, _i, _len;
        handlers = [new NumberOnFieldHandler, new LastOnFieldHandler, new CompareOnFieldHandler];
        for (_i = 0, _len = handlers.length; _i < _len; _i++) {
          handler = handlers[_i];
          if (!handler.applies(onStr)) {
            continue;
          }
          return handler.parseDate(onStr, year, month);
        }
        throw new Error("Unable to parse 'on' field for " + this.name + "|" + this._from + "|" + this._to + "|" + onStr);
      };

      Rule.prototype._parseTime = function(atStr) {
        return helpers.Time.ParseTime(atStr);
      };

      return Rule;

    })();
    RuleSet = (function() {
      function RuleSet(rules, timeZone) {
        var beginYears, commonUpdateYearEnds, endYears, max, min, rule, _i, _len, _ref,
          _this = this;
        this.rules = rules != null ? rules : [];
        this.timeZone = timeZone;
        min = null;
        max = null;
        endYears = {};
        beginYears = {};
        _ref = this.rules;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          rule = _ref[_i];
          rule.forZone(this.timeZone.offset, function() {
            return helpers.noSave;
          });
          if (min === null || rule.from < min) {
            min = rule.from;
          }
          if (max === null || rule.to > max) {
            max = rule.to;
          }
          endYears[rule.to] = endYears[rule.to] || [];
          endYears[rule.to].push(rule);
          beginYears[rule.from] = beginYears[rule.from] || [];
          beginYears[rule.from].push(rule);
        }
        this.minYear = min;
        this.maxYear = max;
        commonUpdateYearEnds = function(end, years) {
          var lastRule, year, yearRules, _results;
          if (end == null) {
            end = "toUTC";
          }
          if (years == null) {
            years = endYears;
          }
          _results = [];
          for (year in years) {
            if (!__hasProp.call(years, year)) continue;
            rules = years[year];
            yearRules = _this.allThatAppliesTo(rules[0][end]);
            if (yearRules.length < 1) {
              continue;
            }
            rules = _this._sortRulesByOnTime(rules);
            lastRule = yearRules.slice(-1)[0];
            if (lastRule.save.hours === 0 && lastRule.save.mins === 0) {
              continue;
            }
            _results.push((function() {
              var _j, _len1, _results1;
              _results1 = [];
              for (_j = 0, _len1 = rules.length; _j < _len1; _j++) {
                rule = rules[_j];
                _results1.push(rule[end] = helpers.Time.ApplySave(rule[end], lastRule.save));
              }
              return _results1;
            })());
          }
          return _results;
        };
        commonUpdateYearEnds("toUTC", endYears);
        commonUpdateYearEnds("fromUTC", beginYears);
      }

      RuleSet.prototype.allThatAppliesTo = function(dt) {
        var rule, _i, _len, _ref, _results;
        _ref = this.rules;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          rule = _ref[_i];
          if (rule.appliesToUTC(dt)) {
            _results.push(rule);
          }
        }
        return _results;
      };

      RuleSet.prototype.getWallTimeForUTC = function(dt) {
        var appliedRules, getPrevRuleSave, lastSave, rule, rules, _i, _len;
        rules = this.allThatAppliesTo(dt);
        if (rules.length < 1) {
          return new TimeZoneTime(dt, this.timeZone, helpers.noSave);
        }
        rules = this._sortRulesByOnTime(rules);
        getPrevRuleSave = function(r) {
          var idx;
          idx = rules.indexOf(r);
          if (idx < 1) {
            if (rules.length < 1) {
              return helpers.noSave;
            }
            return rules.slice(-1)[0].save;
          }
          return rules[idx - 1].save;
        };
        for (_i = 0, _len = rules.length; _i < _len; _i++) {
          rule = rules[_i];
          rule.setOnUTC(dt.getUTCFullYear(), this.timeZone.offset, getPrevRuleSave);
        }
        appliedRules = (function() {
          var _j, _len1, _results;
          _results = [];
          for (_j = 0, _len1 = rules.length; _j < _len1; _j++) {
            rule = rules[_j];
            if (rule.onUTC.getTime() < dt.getTime()) {
              _results.push(rule);
            }
          }
          return _results;
        })();
        lastSave = rules.length < 1 ? helpers.noSave : rules.slice(-1)[0].save;
        if (appliedRules.length > 0) {
          lastSave = appliedRules.slice(-1)[0].save;
        }
        return new TimeZoneTime(dt, this.timeZone, lastSave);
      };

      RuleSet.prototype.getUTCForWallTime = function(dt) {
        var appliedRules, getPrevRuleSave, lastSave, rule, rules, utcStd, _i, _len;
        utcStd = helpers.Time.StandardTimeToUTC(this.timeZone.offset, dt);
        rules = (function() {
          var _i, _len, _ref, _results;
          _ref = this.rules;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            rule = _ref[_i];
            if (rule.appliesToUTC(utcStd)) {
              _results.push(rule);
            }
          }
          return _results;
        }).call(this);
        if (rules.length < 1) {
          return utcStd;
        }
        rules = this._sortRulesByOnTime(rules);
        getPrevRuleSave = function(r) {
          var idx;
          idx = rules.indexOf(r);
          if (idx < 1) {
            if (rules.length < 1) {
              return helpers.noSave;
            }
            return rules.slice(-1)[0].save;
          }
          return rules[idx - 1].save;
        };
        for (_i = 0, _len = rules.length; _i < _len; _i++) {
          rule = rules[_i];
          rule.setOnUTC(utcStd.getUTCFullYear(), this.timeZone.offset, getPrevRuleSave);
        }
        appliedRules = (function() {
          var _j, _len1, _results;
          _results = [];
          for (_j = 0, _len1 = rules.length; _j < _len1; _j++) {
            rule = rules[_j];
            if (rule.onUTC.getTime() < utcStd.getTime()) {
              _results.push(rule);
            }
          }
          return _results;
        })();
        lastSave = rules.length < 1 ? helpers.noSave : rules.slice(-1)[0].save;
        if (appliedRules.length > 0) {
          lastSave = appliedRules.slice(-1)[0].save;
        }
        return helpers.Time.WallTimeToUTC(this.timeZone.offset, lastSave, dt);
      };

      RuleSet.prototype.getYearEndDST = function(dt) {
        var appliedRules, getPrevRuleSave, lastSave, rule, rules, utcStd, year, _i, _len;
        year = typeof dt === number ? dt : dt.getUTCFullYear();
        utcStd = helpers.Time.StandardTimeToUTC(this.timeZone.offset, year, 11, 31, 23, 59, 59);
        rules = (function() {
          var _i, _len, _ref, _results;
          _ref = this.rules;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            rule = _ref[_i];
            if (rule.appliesToUTC(utcStd)) {
              _results.push(rule);
            }
          }
          return _results;
        }).call(this);
        if (rules.length < 1) {
          return helpers.noSave;
        }
        rules = this._sortRulesByOnTime(rules);
        getPrevRuleSave = function(r) {
          var idx;
          idx = rules.indexOf(r);
          if (idx < 1) {
            return helpers.noSave;
          }
          return rules[idx - 1].save;
        };
        for (_i = 0, _len = rules.length; _i < _len; _i++) {
          rule = rules[_i];
          rule.setOnUTC(utcStd.getUTCFullYear(), this.timeZone.offset, getPrevRuleSave);
        }
        appliedRules = (function() {
          var _j, _len1, _results;
          _results = [];
          for (_j = 0, _len1 = rules.length; _j < _len1; _j++) {
            rule = rules[_j];
            if (rule.onUTC.getTime() < utcStd.getTime()) {
              _results.push(rule);
            }
          }
          return _results;
        })();
        lastSave = helpers.noSave;
        if (appliedRules.length > 0) {
          lastSave = appliedRules.slice(-1)[0].save;
        }
        return lastSave;
      };

      RuleSet.prototype.isAmbiguous = function(dt) {
        var appliedRules, getPrevRuleSave, lastRule, makeAmbigRange, minsOff, prevSave, range, rule, rules, springForward, totalMinutes, utcStd, _i, _len;
        utcStd = helpers.Time.StandardTimeToUTC(this.timeZone.offset, dt);
        rules = (function() {
          var _i, _len, _ref, _results;
          _ref = this.rules;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            rule = _ref[_i];
            if (rule.appliesToUTC(utcStd)) {
              _results.push(rule);
            }
          }
          return _results;
        }).call(this);
        if (rules.length < 1) {
          return false;
        }
        rules = this._sortRulesByOnTime(rules);
        getPrevRuleSave = function(r) {
          var idx;
          idx = rules.indexOf(r);
          if (idx < 1) {
            return helpers.noSave;
          }
          return rules[idx - 1].save;
        };
        for (_i = 0, _len = rules.length; _i < _len; _i++) {
          rule = rules[_i];
          rule.setOnUTC(utcStd.getUTCFullYear(), this.timeZone.offset, getPrevRuleSave);
        }
        appliedRules = (function() {
          var _j, _len1, _results;
          _results = [];
          for (_j = 0, _len1 = rules.length; _j < _len1; _j++) {
            rule = rules[_j];
            if (rule.onUTC.getTime() <= utcStd.getTime() - 1) {
              _results.push(rule);
            }
          }
          return _results;
        })();
        if (appliedRules.length < 1) {
          return false;
        }
        lastRule = appliedRules.slice(-1)[0];
        prevSave = getPrevRuleSave(lastRule);
        totalMinutes = {
          prev: (prevSave.hours * 60) + prevSave.mins,
          last: (lastRule.save.hours * 60) + lastRule.save.mins
        };
        if (totalMinutes.prev === totalMinutes.last) {
          return false;
        }
        springForward = totalMinutes.prev < totalMinutes.last;
        makeAmbigRange = function(begin, minutesOff) {
          var ambigRange, tmp;
          ambigRange = {
            begin: helpers.Time.MakeDateFromTimeStamp(begin.getTime() + 1)
          };
          ambigRange.end = helpers.Time.Add(ambigRange.begin, 0, minutesOff);
          if (ambigRange.begin.getTime() > ambigRange.end.getTime()) {
            tmp = ambigRange.begin;
            ambigRange.begin = ambigRange.end;
            ambigRange.end = tmp;
          }
          return ambigRange;
        };
        minsOff = springForward ? totalMinutes.last : -totalMinutes.prev;
        range = makeAmbigRange(lastRule.onUTC, minsOff);
        utcStd = helpers.Time.WallTimeToUTC(this.timeZone.offset, prevSave, dt);
        return (range.begin <= utcStd && utcStd <= range.end);
      };

      RuleSet.prototype._sortRulesByOnTime = function(rules) {
        return rules.sort(function(a, b) {
          return (helpers.Months.MonthIndex(a["in"])) - (helpers.Months.MonthIndex(b["in"]));
        });
      };

      return RuleSet;

    })();
    lib = {
      Rule: Rule,
      RuleSet: RuleSet,
      OnFieldHandlers: {
        NumberHandler: NumberOnFieldHandler,
        LastHandler: LastOnFieldHandler,
        CompareHandler: CompareOnFieldHandler
      }
    };
    return lib;
  };

  if (typeof window === 'undefined') {
    req_helpers = require("./helpers");
    req_TimeZoneTime = require("./timezonetime");
    module.exports = init(req_helpers, req_TimeZoneTime);
  } else if (typeof define !== 'undefined') {
    define(["olson/helpers", "olson/timezonetime"], init);
  } else {
    this.WallTime || (this.WallTime = {});
    this.WallTime.rule = init(this.WallTime.helpers, this.WallTime.TimeZoneTime);
  }

}).call(this);
