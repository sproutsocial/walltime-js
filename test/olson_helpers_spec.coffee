should = require "should"
helpers = require "../lib/olson/helpers"

describe "Olson Helpers", ->
    
    describe "Time Helpers", ->
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

        it "can MakeDateFromParts correctly for 2012 before Daylight Savings using default constructor", ->
            commonDateCompare 2012, 3-1, 11, 1, 59, 59, 999

        it "can MakeDateFromParts correctly for 2012 after Daylight Savings using default constructor", ->
            # Note the change over to 3:00 for this time zone
            commonDateCompare 2012, 3-1, 11, 2, 0, 0, 0

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
            # Start with 1/10/1920 12:00 UTC
            origDate = helpers.Time.MakeDateFromParts(1920, 0, 10, 12)
            offset = 
                negative: true
                hours: 5
                mins: 50
                secs: 36

            # Apply our offset of -5:50:36
            utcDate = helpers.Time.ApplyOffset origDate, offset

            # Should be 1/10/1920 5:50:36 UTC
            utcDate.should.equal helpers.Time.MakeDateFromParts(1920, 0, 10, 17, 50, 36)

            offset.negative = false
            offset.mins = 0
            offset.secs = 0

            # Apply an offset of + 5 hours
            utcDate = helpers.Time.ApplyOffset origDate, offset

            # Should be 1/10/1920 7:00 UTC
            utcDate.should.equal helpers.Time.MakeDateFromParts(1920, 0, 10, 7)

        it "can apply a SAVE value", ->
            # Start with 1/10/1920 12:00
            origDate = helpers.Time.MakeDateFromParts(1920, 0, 10, 12)
            expectDate = helpers.Time.MakeDateFromParts(1920, 0, 10, 13)

            save =
                hours: 1
                mins: 0

            result = helpers.Time.ApplySave origDate, save

            result.should.equal expectDate

        it "can generate a standard time", ->
            offset = 
                negative: true
                hours: 6
                mins: 0
                secs: 0

            utc = helpers.Time.MakeDateFromParts 1920, 0, 10, 12
            expect = helpers.Time.ApplyOffset utc, offset, true

            result = helpers.Time.UTCToStandardTime utc, offset

            result.should.equal expect

            result.getUTCHours().should.equal 6

        it "can generate a utc time from a standard time and offset", ->
            offset = 
                negative: true
                hours: 6
                mins: 0
                secs: 0

            # Standard time of 1/10/1920 12:00 PM with -6:00:00 offset
            result = helpers.Time.StandardTimeToUTC offset, 1920, 0, 10, 12
            # Should be UTC time of 1/10/1920 18:00 PM
            expect = helpers.Time.MakeDateFromParts 1920, 0, 10, 18

            result.should.equal expect

            result.getUTCHours().should.equal 18

        it "can generate qualified time", ->
            getSave = -> 
                hours: 1
                mins: 0

            offset = 
                negative: true
                hours: 6
                mins: 0
                secs: 0

            utc = helpers.Time.MakeDateFromParts 1920, 0, 10, 12
            
            # UTC Time
            expect = utc
            result = helpers.Time.UTCToQualifiedTime utc, "u", offset, getSave

            result.should.equal expect, "UTC Time"
            result.getUTCHours().should.equal 12

            # Standard Time
            expect = helpers.Time.ApplyOffset utc, offset, true
            result = helpers.Time.UTCToQualifiedTime utc, "s", offset, getSave

            result.should.equal expect, "Standard Time"
            result.getUTCHours().should.equal 6

            # Wall Time
            expect = helpers.Time.ApplySave expect, getSave()
            result = helpers.Time.UTCToQualifiedTime utc, "w", offset, getSave

            result.should.equal expect, "Wall Time"
            result.getUTCHours().should.equal 7

        it "can generate utc from qualified time", ->
            getSave = -> 
                hours: 1
                mins: 0

            offset = 
                negative: true
                hours: 6
                mins: 0
                secs: 0

            utc = helpers.Time.MakeDateFromParts 1920, 0, 10, 12

            # UTC Time
            expect = utc
            result = helpers.Time.QualifiedTimeToUTC utc, "u", offset, getSave

            result.should.equal expect, "UTC Time"
            result.getUTCHours().should.equal 12

            # Standard Time
            expect = helpers.Time.StandardTimeToUTC offset, utc
            result = helpers.Time.QualifiedTimeToUTC utc, "s", offset, getSave
            # 12:00 with a -6:00 offset should be 18:00 in standard time
            result.getUTCHours().should.equal 18

            # Wall Time
            expect = helpers.Time.WallTimeToUTC offset, getSave(), utc
            result = helpers.Time.QualifiedTimeToUTC utc, "w", offset, getSave
            # 12:00 with a -6:00 offset and 1:00 save should be -5:00 offset
            result.getUTCHours().should.equal 17

