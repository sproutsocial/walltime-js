should = require "should"
helpers = require "../lib/olson/helpers"

describe "Javascript Dates", ->
    # These are tests to confirm my assumptions about javascript dates
    commonDateCompare = (y, m, d, h, mi, s, ms) ->
        dt = helpers.Time.MakeDateFromParts y, m, d, h, mi, s, ms

        dt.getUTCFullYear().should.equal y, "year"
        dt.getUTCMonth().should.equal m, "month"
        dt.getUTCDate().should.equal d, "day"
        dt.getUTCHours().should.equal h, "hour"
        dt.getUTCMinutes().should.equal mi, "minute"
        dt.getUTCSeconds().should.equal s, "second"
        dt.getUTCMilliseconds().should.equal ms, "millisecond"

    it "are correct for 2012 before Daylight Savings using default constructor", ->
        commonDateCompare 2012, 3-1, 11, 1, 59, 59, 999

    it "are correct for 2012 after Daylight Savings using default constructor", ->
        # Note the change over to 3:00 for this time zone
        commonDateCompare 2012, 3-1, 11, 2, 0, 0, 0

describe "Olson Helpers", ->
    
    describe "Time Helpers", ->
        it "can parse times", ->
            [hours, mins, qual] = helpers.Time.ParseTime "23:00"

            hours.should.equal 23
            mins.should.equal 0
            qual.should.equal ''

            [hours, mins, qual] = helpers.Time.ParseTime "23:00u"

            hours.should.equal 23
            mins.should.equal 0
            qual.should.equal "u"

        it "can parse GMT offsets", ->
            [negative, hour, minute, seconds] = helpers.Time.ParseGMTOffset "-5:50:36"

            negative.should.equal true, "negative"
            hour.should.equal 5, "hour"
            minute.should.equal 50, "minute"
            seconds.should.equal 36, "seconds"

            [negative, hour, minute, seconds] = helpers.Time.ParseGMTOffset "5:00"

            negative.should.equal false, "negative2"
            hour.should.equal 5, "hour2"
            minute.should.equal 0, "minute2"
            (isNaN seconds).should.equal true, "seconds2"

        it "can apply an offset", ->
            # Start with 1/10/1920 12:00
            origDate = helpers.Time.MakeDateFromParts(1920, 0, 10, 12)
            offset = 
                negative: true
                hours: 5
                mins: 50
                secs: 36

            # Apply our offset of -5:50:36
            utcDate = helpers.Time.ApplyOffset origDate, offset

            # Should be 1/10/1920 17:50:36
            utcDate.should.equal helpers.Time.MakeDateFromParts(1920, 0, 10, 17, 50, 36)

            offset.negative = false
            offset.mins = 0
            offset.secs = 0

            # Apply an offset of + 5 hours
            utcDate = helpers.Time.ApplyOffset origDate, offset

            # Should be 1/10/1920 17:00
            utcDate.should.equal helpers.Time.MakeDateFromParts(1920, 0, 10, 7)
            
