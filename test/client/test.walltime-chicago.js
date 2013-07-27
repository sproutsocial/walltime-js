
describe("WallTime - Chicago Data", function () {
    var itshould = chai.should();

    it("has Chicago data", function () {
        itshould.exist(WallTime.data.zones["America/Chicago"]);
    });

    it("can convert first moon landing time", function () {
        // Apollo 11 was the spaceflight that landed the first humans on the Moon, 
        // Americans Neil Armstrong and Buzz Aldrin, on July 20, 1969, at 20:18 UTC.
        var landingTime = Date.UTC(1969, 6, 20, 20, 18, 0, 0),
            chicagoLandingTime = WallTime.UTCToWallTime(landingTime, "America/Chicago");

        chicagoLandingTime.getFullYear().should.equal(1969);
        chicagoLandingTime.getMonth().should.equal(6);
        chicagoLandingTime.getDate().should.equal(20);
        chicagoLandingTime.getHours().should.equal(15);
        chicagoLandingTime.getMinutes().should.equal(18);
    });

    it("can convert Jul 26 2013, 6:50 AM", function () {
        var chicagoTime = WallTime.UTCToWallTime(new Date(1374839400000), "America/Chicago");

        chicagoTime.getFullYear().should.equal(2013);
        chicagoTime.getMonth().should.equal(6);
        chicagoTime.getDate().should.equal(26);
        chicagoTime.getHours().should.equal(6);
        chicagoTime.getMinutes().should.equal(50);
    });
});