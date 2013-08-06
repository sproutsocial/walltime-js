/*
 *  WallTime 0.2.0
 *  Copyright (c) 2013 Sprout Social, Inc.
 *  Available under the MIT License (http://bit.ly/walltime-license)
 */
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
    define(["olson/helpers"], init);
  } else {
    this.WallTime || (this.WallTime = {});
    this.WallTime.TimeZoneTime = init(this.WallTime.helpers);
  }

}).call(this);
