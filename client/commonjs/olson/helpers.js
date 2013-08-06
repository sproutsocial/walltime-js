/*
 *  WallTime 0.2.0
 *  Copyright (c) 2013 Sprout Social, Inc.
 *  Available under the MIT License (http://bit.ly/walltime-license)
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
    define(helpers);
  } else {
    this.WallTime || (this.WallTime = {});
    this.WallTime.helpers = helpers;
  }

}).call(this);
