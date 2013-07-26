
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
        chicagoLandingTime.getHours().should.equal(14);
        chicagoLandingTime.getMinutes().should.equal(18);
    });
});