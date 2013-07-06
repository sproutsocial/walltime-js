
describe("WallTime API", function () {
    var itshould = chai.should();

    it("has an init function", function () {
        itshould.exist(WallTime.init);
    });

    it("allows you to set the timezone", function () {
        itshould.exist(WallTime.setTimeZone);

        WallTime.setTimeZone("America/Chicago");

        WallTime.zoneSet.name.should.equal("America/Chicago");
    });
});