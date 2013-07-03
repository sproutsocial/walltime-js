/*
 *  WallTime 0.0.16
 *  Copyright (c) 2013 Sprout Social, Inc.
 *  Available under the MIT License (https://github.com/sproutsocial/walltime-js/blob/master/LICENSE)
 */
 
(function() {
  var Days, Milliseconds, Months, Time, helpers, _base;

  (_base = Array.prototype).indexOf || (_base.indexOf = function(item) {
    var i, x, _i, _len;
    for (i = _i = 0, _len = this.length; _i < _len; i = ++_i) {
      x = this[i];
      if (x === item) {
        return i;
      }
    }
    return -1;
  });

  Days = {
    DayShortNames: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
    DayIndex: function(name) {
      return this.DayShortNames.indexOf(name);
    },
    DayNameFromIndex: function(dayIdx) {
      return this.DayShortNames[dayIdx];
    },
    AddToDate: function(dt, days) {
      return Time.MakeDateFromTimeStamp(dt.getTime() + (days * Milliseconds.inDay));
    }
  };

  Months = {
    MonthsShortNames: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
    CompareRuleMatch: new RegExp("([a-zA-Z]*)([\\<\\>]?=)([0-9]*)"),
    MonthIndex: function(shortName) {
      return this.MonthsShortNames.indexOf(shortName.slice(0, 3));
    },
    IsDayOfMonthRule: function(str) {
      return str.indexOf(">") > -1 || str.indexOf("<") > -1 || str.indexOf("=") > -1;
    },
    IsLastDayOfMonthRule: function(str) {
      return str.slice(0, 4) === "last";
    },
    DayOfMonthByRule: function(str, year, month) {
      var compareFunc, compares, dateIndex, dayIndex, dayName, ruleParse, testDate, testPart, _ref;
      ruleParse = this.CompareRuleMatch.exec(str);
      if (!ruleParse) {
        throw new Error("Unable to parse the 'on' rule for " + str);
      }
      _ref = ruleParse.slice(1, 4), dayName = _ref[0], testPart = _ref[1], dateIndex = _ref[2];
      dateIndex = parseInt(dateIndex, 10);
      if (dateIndex === NaN) {
        throw new Error("Unable to parse the dateIndex of the 'on' rule for " + str);
      }
      dayIndex = helpers.Days.DayIndex(dayName);
      compares = {
        ">=": function(a, b) {
          return a >= b;
        },
        "<=": function(a, b) {
          return a <= b;
        },
        ">": function(a, b) {
          return a > b;
        },
        "<": function(a, b) {
          return a < b;
        },
        "=": function(a, b) {
          return a === b;
        }
      };
      compareFunc = compares[testPart];
      if (!compareFunc) {
        throw new Error("Unable to parse the conditional for " + testPart);
      }
      testDate = helpers.Time.MakeDateFromParts(year, month);
      while (!(dayIndex === testDate.getUTCDay() && compareFunc(testDate.getUTCDate(), dateIndex))) {
        testDate = helpers.Days.AddToDate(testDate, 1);
      }
      return testDate.getUTCDate();
    },
    LastDayOfMonthRule: function(str, year, month) {
      var dayIndex, dayName, lastDay;
      dayName = str.slice(4);
      dayIndex = helpers.Days.DayIndex(dayName);
      if (month < 11) {
        lastDay = helpers.Time.MakeDateFromParts(year, month + 1);
      } else {
        lastDay = helpers.Time.MakeDateFromParts(year + 1, 0);
      }
      lastDay = helpers.Days.AddToDate(lastDay, -1);
      while (lastDay.getUTCDay() !== dayIndex) {
        lastDay = helpers.Days.AddToDate(lastDay, -1);
      }
      return lastDay.getUTCDate();
    }
  };

  Milliseconds = {
    inDay: 86400000,
    inHour: 3600000,
    inMinute: 60000,
    inSecond: 1000
  };

  Time = {
    Add: function(dt, hours, mins, secs) {
      var newTs;
      if (hours == null) {
        hours = 0;
      }
      if (mins == null) {
        mins = 0;
      }
      if (secs == null) {
        secs = 0;
      }
      newTs = dt.getTime() + (hours * Milliseconds.inHour) + (mins * Milliseconds.inMinute) + (secs * Milliseconds.inSecond);
      return this.MakeDateFromTimeStamp(newTs);
    },
    ParseGMTOffset: function(str) {
      var isNeg, match, matches, reg, result;
      reg = new RegExp("(-)?([0-9]*):([0-9]*):?([0-9]*)?");
      matches = reg.exec(str);
      result = matches ? (function() {
        var _i, _len, _ref, _results;
        _ref = matches.slice(2);
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          match = _ref[_i];
          _results.push(parseInt(match, 10));
        }
        return _results;
      })() : [0, 0, 0];
      isNeg = matches && matches[1] === "-";
      result.splice(0, 0, isNeg);
      return result;
    },
    ParseTime: function(str) {
      var match, matches, qual, reg, timeParts;
      reg = new RegExp("(\\d*)\\:(\\d*)([wsugz]?)");
      matches = reg.exec(str);
      if (!matches) {
        return [0, 0, ''];
      }
      timeParts = (function() {
        var _i, _len, _ref, _results;
        _ref = matches.slice(1, 3);
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          match = _ref[_i];
          _results.push(parseInt(match, 10));
        }
        return _results;
      })();
      qual = matches[3] ? matches[3] : '';
      timeParts.push(qual);
      return timeParts;
    },
    ApplyOffset: function(dt, offset, reverse) {
      var offset_ms;
      offset_ms = (Milliseconds.inHour * offset.hours) + (Milliseconds.inMinute * offset.mins) + (Milliseconds.inSecond * offset.secs);
      if (!offset.negative) {
        offset_ms = offset_ms * -1;
      }
      if (reverse) {
        offset_ms = offset_ms * -1;
      }
      return this.MakeDateFromTimeStamp(dt.getTime() + offset_ms);
    },
    ApplySave: function(dt, save, reverse) {
      if (reverse !== true) {
        reverse = false;
      }
      return this.ApplyOffset(dt, {
        negative: true,
        hours: save.hours,
        mins: save.mins,
        secs: 0
      }, reverse);
    },
    UTCToWallTime: function(dt, offset, save) {
      var endTime;
      endTime = this.UTCToStandardTime(dt, offset);
      return this.ApplySave(endTime, save);
    },
    UTCToStandardTime: function(dt, offset) {
      return this.ApplyOffset(dt, offset, true);
    },
    UTCToQualifiedTime: function(dt, qualifier, offset, getSave) {
      var endTime;
      endTime = dt;
      switch (qualifier) {
        case "w":
          endTime = this.UTCToWallTime(endTime, offset, getSave());
          break;
        case "s":
          endTime = this.UTCToStandardTime(endTime, offset);
          break;
      }
      return endTime;
    },
    QualifiedTimeToUTC: function(dt, qualifier, offset, getSave) {
      var endTime;
      endTime = dt;
      switch (qualifier) {
        case "w":
          endTime = this.WallTimeToUTC(offset, getSave(), endTime);
          break;
        case "s":
          endTime = this.StandardTimeToUTC(offset, endTime);
          break;
      }
      return endTime;
    },
    StandardTimeToUTC: function(offset, y, m, d, h, mi, s, ms) {
      var dt;
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
      dt = typeof y === "number" ? this.MakeDateFromParts(y, m, d, h, mi, s, ms) : y;
      return this.ApplyOffset(dt, offset);
    },
    WallTimeToUTC: function(offset, save, y, m, d, h, mi, s, ms) {
      var dt;
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
      dt = this.StandardTimeToUTC(offset, y, m, d, h, mi, s, ms);
      return this.ApplySave(dt, save, true);
    },
    MakeDateFromParts: function(y, m, d, h, mi, s, ms) {
      var dt;
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
      if (Date.UTC) {
        return new Date(Date.UTC(y, m, d, h, mi, s, ms));
      }
      dt = new Date;
      dt.setUTCFullYear(y);
      dt.setUTCMonth(m);
      dt.setUTCDate(d);
      dt.setUTCHours(h);
      dt.setUTCMinutes(mi);
      dt.setUTCSeconds(s);
      dt.setUTCMilliseconds(ms);
      return dt;
    },
    LocalDate: function(offset, save, y, m, d, h, mi, s, ms) {
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
      return this.WallTimeToUTC(offset, save, y, m, d, h, mi, s, ms);
    },
    MakeDateFromTimeStamp: function(ts) {
      return new Date(ts);
    },
    MaxDate: function() {
      return this.MakeDateFromTimeStamp(10000000 * 86400000);
    },
    MinDate: function() {
      return this.MakeDateFromTimeStamp(-10000000 * 86400000);
    }
  };

  helpers = {
    Days: Days,
    Months: Months,
    Milliseconds: Milliseconds,
    Time: Time,
    noSave: {
      hours: 0,
      mins: 0
    },
    noZone: {
      offset: {
        negative: false,
        hours: 0,
        mins: 0,
        secs: 0
      },
      name: "UTC"
    }
  };

  if (typeof window === 'undefined') {
    module.exports = helpers;
  } else if (typeof define !== 'undefined') {
    define('olson/helpers',helpers);
  } else {
    this.WallTime || (this.WallTime = {});
    this.WallTime.helpers = helpers;
  }

}).call(this);

(function() {
  var init, req_helpers;

  init = function(helpers) {
    var TimeZoneTime;
    TimeZoneTime = (function() {
      function TimeZoneTime(utc, zone, save) {
        this.utc = utc;
        this.zone = zone;
        this.save = save;
        this.offset = this.zone.offset;
        this.wallTime = helpers.Time.UTCToWallTime(this.utc, this.offset, this.save);
      }

      TimeZoneTime.prototype.getFullYear = function() {
        return this.wallTime.getUTCFullYear();
      };

      TimeZoneTime.prototype.getMonth = function() {
        return this.wallTime.getUTCMonth();
      };

      TimeZoneTime.prototype.getDate = function() {
        return this.wallTime.getUTCDate();
      };

      TimeZoneTime.prototype.getDay = function() {
        return this.wallTime.getUTCDay();
      };

      TimeZoneTime.prototype.getHours = function() {
        return this.wallTime.getUTCHours();
      };

      TimeZoneTime.prototype.getMinutes = function() {
        return this.wallTime.getUTCMinutes();
      };

      TimeZoneTime.prototype.getSeconds = function() {
        return this.wallTime.getUTCSeconds();
      };

      TimeZoneTime.prototype.getMilliseconds = function() {
        return this.wallTime.getUTCMilliseconds();
      };

      TimeZoneTime.prototype.getUTCFullYear = function() {
        return this.utc.getUTCFullYear();
      };

      TimeZoneTime.prototype.getUTCMonth = function() {
        return this.utc.getUTCMonth();
      };

      TimeZoneTime.prototype.getUTCDate = function() {
        return this.utc.getUTCDate();
      };

      TimeZoneTime.prototype.getUTCDay = function() {
        return this.utc.getUTCDay();
      };

      TimeZoneTime.prototype.getUTCHours = function() {
        return this.utc.getUTCHours();
      };

      TimeZoneTime.prototype.getUTCMinutes = function() {
        return this.utc.getUTCMinutes();
      };

      TimeZoneTime.prototype.getUTCSeconds = function() {
        return this.utc.getUTCSeconds();
      };

      TimeZoneTime.prototype.getUTCMilliseconds = function() {
        return this.utc.getUTCMilliseconds();
      };

      TimeZoneTime.prototype.getTime = function() {
        return this.utc.getTime();
      };

      TimeZoneTime.prototype.getTimezoneOffset = function() {
        var base, dst;
        base = (this.offset.hours * 60) + this.offset.mins;
        dst = (this.save.hours * 60) + this.save.mins;
        if (!this.offset.negative) {
          base = -base;
        }
        return base - dst;
      };

      TimeZoneTime.prototype.toISOString = function() {
        return this.utc.toISOString();
      };

      TimeZoneTime.prototype.toUTCString = function() {
        return this.wallTime.toUTCString();
      };

      TimeZoneTime.prototype.toDateString = function() {
        var caps, utcStr;
        utcStr = this.wallTime.toUTCString();
        caps = utcStr.match("([a-zA-Z]*), ([0-9]+) ([a-zA-Z]*) ([0-9]+)");
        return [caps[1], caps[3], caps[2], caps[4]].join(" ");
      };

      TimeZoneTime.prototype.toFormattedTime = function(use24HourTime) {
        var hour, meridiem, min, origHour;
        if (use24HourTime == null) {
          use24HourTime = false;
        }
        hour = origHour = this.getHours();
        if (hour > 12 && !use24HourTime) {
          hour -= 12;
        }
        if (hour === 0) {
          hour = 12;
        }
        min = this.getMinutes();
        if (min < 10) {
          min = "0" + min;
        }
        meridiem = origHour > 11 ? ' PM' : ' AM';
        if (use24HourTime) {
          meridiem = '';
        }
        return "" + hour + ":" + min + meridiem;
      };

      TimeZoneTime.prototype.setTime = function(ms) {
        this.wallTime = helpers.Time.UTCToWallTime(new Date(ms), this.zone.offset, this.save);
        return this._updateUTC();
      };

      TimeZoneTime.prototype.setFullYear = function(y) {
        this.wallTime.setUTCFullYear(y);
        return this._updateUTC();
      };

      TimeZoneTime.prototype.setMonth = function(m) {
        this.wallTime.setUTCMonth(m);
        return this._updateUTC();
      };

      TimeZoneTime.prototype.setDate = function(utcDate) {
        this.wallTime.setUTCDate(utcDate);
        return this._updateUTC();
      };

      TimeZoneTime.prototype.setHours = function(hours) {
        this.wallTime.setUTCHours(hours);
        return this._updateUTC();
      };

      TimeZoneTime.prototype.setMinutes = function(m) {
        this.wallTime.setUTCMinutes(m);
        return this._updateUTC();
      };

      TimeZoneTime.prototype.setSeconds = function(s) {
        this.wallTime.setUTCSeconds(s);
        return this._updateUTC();
      };

      TimeZoneTime.prototype.setMilliseconds = function(ms) {
        this.wallTime.setUTCMilliseconds(ms);
        return this._updateUTC();
      };

      TimeZoneTime.prototype._updateUTC = function() {
        this.utc = helpers.Time.WallTimeToUTC(this.offset, this.save, this.getFullYear(), this.getMonth(), this.getDate(), this.getHours(), this.getMinutes(), this.getSeconds(), this.getMilliseconds());
        return this.utc.getTime();
      };

      return TimeZoneTime;

    })();
    return TimeZoneTime;
  };

  if (typeof window === 'undefined') {
    req_helpers = require("./helpers");
    module.exports = init(req_helpers);
  } else if (typeof define !== 'undefined') {
    define('olson/timezonetime',["olson/helpers"], init);
  } else {
    this.WallTime || (this.WallTime = {});
    this.WallTime.TimeZoneTime = init(this.WallTime.helpers);
  }

}).call(this);

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
    define('olson/rule',["olson/helpers", "olson/timezonetime"], init);
  } else {
    this.WallTime || (this.WallTime = {});
    this.WallTime.rule = init(this.WallTime.helpers, this.WallTime.TimeZoneTime);
  }

}).call(this);

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
    define('olson/zone',["olson/helpers", "olson/rule", "olson/timezonetime"], init);
  } else {
    this.WallTime || (this.WallTime = {});
    this.WallTime.zone = init(this.WallTime.helpers, this.WallTime.rule, this.WallTime.TimeZoneTime);
  }

}).call(this);

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
    define('walltime',['olson/helpers', 'olson/rule', 'olson/zone'], init);
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
