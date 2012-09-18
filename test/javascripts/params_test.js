//= require_self
//= require jquery
//= require jquery.cookie
//= require params

window.OSM = {};

describe("OSM.mapParams()", function () {
  beforeEach(function () {
    delete OSM.home;
    delete OSM.location;
    document.cookie = "_osm_location=; expires=Thu, 01 Jan 1970 00:00:00 GMT";

    // Test with another cookie set.
    document.cookie = "_osm_session=deadbeef";
  });

  it("parses marker params", function () {
    var params = OSM.mapParams("?mlat=57.6247&mlon=-3.6845");
    expect(params).to.have.property("mlat", 57.6247);
    expect(params).to.have.property("mlon", -3.6845);
    expect(params).to.have.property("marker", true);
  });

  it("parses object params", function () {
    var params = OSM.mapParams("?node=1");
    expect(params).to.have.property("object", true);
    expect(params).to.have.property("object_zoom", true);
    expect(params).to.have.property("object_type", "node");
    expect(params).to.have.property("object_id", 1);

    params = OSM.mapParams("?way=1");
    expect(params).to.have.property("object", true);
    expect(params).to.have.property("object_zoom", true);
    expect(params).to.have.property("object_type", "way");
    expect(params).to.have.property("object_id", 1);

    params = OSM.mapParams("?relation=1");
    expect(params).to.have.property("object", true);
    expect(params).to.have.property("object_zoom", true);
    expect(params).to.have.property("object_type", "relation");
    expect(params).to.have.property("object_id", 1);
  });

  it("parses bbox params", function () {
    var params = OSM.mapParams("?bbox=-3.6845,57.6247,-3.7845,57.7247");
    expect(params).to.have.property("bbox", true);
    expect(params).to.have.property("minlon", -3.6845);
    expect(params).to.have.property("minlat", 57.6247);
    expect(params).to.have.property("maxlon", -3.7845);
    expect(params).to.have.property("maxlat", 57.7247);
    expect(params).to.have.property("box", false);

    params = OSM.mapParams("?minlon=-3.6845&minlat=57.6247&maxlon=-3.7845&maxlat=57.7247");
    expect(params).to.have.property("bbox", true);
    expect(params).to.have.property("minlon", -3.6845);
    expect(params).to.have.property("minlat", 57.6247);
    expect(params).to.have.property("maxlon", -3.7845);
    expect(params).to.have.property("maxlat", 57.7247);
    expect(params).to.have.property("box", false);

    params = OSM.mapParams("?bbox=-3.6845,57.6247,-3.7845,57.7247&box=yes");
    expect(params).to.have.property("box", true);

    params = OSM.mapParams("?minlon=-3.6845&minlat=57.6247&maxlon=-3.7845&maxlat=57.7247&box=yes");
    expect(params).to.have.property("box", true);
  });

  it("infers lat/long from bbox", function () {
    var params = OSM.mapParams("?bbox=-3.6845,57.6247,-3.7845,57.7247");
    expect(params).to.have.property("lat", 57.6747);
    expect(params).to.have.property("lon", -3.7344999999999997);

    params = OSM.mapParams("?minlon=-3.6845&minlat=57.6247&maxlon=-3.7845&maxlat=57.7247");
    expect(params).to.have.property("lat", 57.6747);
    expect(params).to.have.property("lon", -3.7344999999999997);
  });

  it("parses lat/lon params", function () {
    var params = OSM.mapParams("?lat=57.6247&lon=-3.6845");
    expect(params).to.have.property("lat", 57.6247);
    expect(params).to.have.property("lon", -3.6845);

    params = OSM.mapParams("?mlat=57.6247&mlon=-3.6845");
    expect(params).to.have.property("lat", 57.6247);
    expect(params).to.have.property("lon", -3.6845);
  });

  it("sets lat/lon from OSM.home", function () {
    OSM.home = {lat: 57.6247, lon: -3.6845};
    var params = OSM.mapParams("?");
    expect(params).to.have.property("lat", 57.6247);
    expect(params).to.have.property("lon", -3.6845);
  });

  it("sets bbox from OSM.location", function () {
    OSM.location = {minlon: -3.6845, minlat: 57.6247, maxlon: -3.7845, maxlat: 57.7247};
    var params = OSM.mapParams("?");
    expect(params).to.have.property("bbox", true);
    expect(params).to.have.property("minlon", -3.6845);
    expect(params).to.have.property("minlat", 57.6247);
    expect(params).to.have.property("maxlon", -3.7845);
    expect(params).to.have.property("maxlat", 57.7247);
  });

  it("parses params from the _osm_location cookie", function () {
    document.cookie = "_osm_location=-3.6845|57.6247|5|M";
    var params = OSM.mapParams("?");
    expect(params).to.have.property("lat", 57.6247);
    expect(params).to.have.property("lon", -3.6845);
    expect(params).to.have.property("zoom", 5);
    expect(params).to.have.property("layers", "M");
  });

  it("defaults lat/lon to London", function () {
    var params = OSM.mapParams("?");
    expect(params).to.have.property("lat", 51.5);
    expect(params).to.have.property("lon", -0.1);
  });

  it("parses layers param", function () {
    var params = OSM.mapParams("?layers=M");
    expect(params).to.have.property("layers", "M");
  });
});
