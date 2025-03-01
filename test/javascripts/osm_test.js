//= require jquery
//= require js-cookie/dist/js.cookie
//= require osm
//= require leaflet/dist/leaflet-src
//= require leaflet.osm
//= require leaflet.map
//= require i18n/translations

describe("OSM", function () {
  describe(".apiUrl", function () {
    it("returns a URL for a way", function () {
      expect(OSM.apiUrl({ type: "way", id: 10 })).to.eq("/api/0.6/way/10/full");
    });

    it("returns a URL for a node", function () {
      expect(OSM.apiUrl({ type: "node", id: 10 })).to.eq("/api/0.6/node/10");
    });

    it("returns a URL for a specific version", function () {
      expect(OSM.apiUrl({ type: "node", id: 10, version: 2 })).to.eq("/api/0.6/node/10/2");
    });
  });

  describe(".params", function () {
    it("parses params", function () {
      const params = OSM.params("?foo=a&bar=b");
      expect(params).to.have.property("foo", "a");
      expect(params).to.have.property("bar", "b");
    });
  });

  describe(".mapParams", function () {
    beforeEach(function () {
      delete OSM.home;
      delete OSM.location;
      location.hash = "";
      document.cookie = "_osm_location=; expires=Thu, 01 Jan 1970 00:00:00 GMT";

      // Test with another cookie set.
      document.cookie = "_osm_session=deadbeef";
    });

    it("parses marker params", function () {
      const params = OSM.mapParams("?mlat=57.6247&mlon=-3.6845");
      expect(params).to.have.property("mlat", 57.6247);
      expect(params).to.have.property("mlon", -3.6845);
      expect(params).to.have.property("marker", true);
    });

    it("parses object params", function () {
      let params = OSM.mapParams("?node=1");
      expect(params).to.have.property("object");
      expect(params.object).to.eql({ type: "node", id: 1 });

      params = OSM.mapParams("?way=1");
      expect(params).to.have.property("object");
      expect(params.object).to.eql({ type: "way", id: 1 });

      params = OSM.mapParams("?relation=1");
      expect(params).to.have.property("object");
      expect(params.object).to.eql({ type: "relation", id: 1 });
    });

    it("parses bbox params", function () {
      const expected = L.latLngBounds([57.6247, -3.6845], [57.7247, -3.7845]);
      let params = OSM.mapParams("?bbox=-3.6845,57.6247,-3.7845,57.7247");
      expect(params).to.have.property("bounds").deep.equal(expected);

      params = OSM.mapParams("?minlon=-3.6845&minlat=57.6247&maxlon=-3.7845&maxlat=57.7247");
      expect(params).to.have.property("bounds").deep.equal(expected);
    });

    it("parses mlat/mlon/zoom params", function () {
      let params = OSM.mapParams("?mlat=57.6247&mlon=-3.6845");
      expect(params).to.have.property("lat", 57.6247);
      expect(params).to.have.property("lon", -3.6845);
      expect(params).to.have.property("zoom", 12);

      params = OSM.mapParams("?mlat=57.6247&mlon=-3.6845&zoom=16");
      expect(params).to.have.property("lat", 57.6247);
      expect(params).to.have.property("lon", -3.6845);
      expect(params).to.have.property("zoom", 16);
    });

    it("parses lat/lon/zoom from the hash", function () {
      location.hash = "#map=16/57.6247/-3.6845";
      const params = OSM.mapParams("?");
      expect(params).to.have.property("lat", 57.6247);
      expect(params).to.have.property("lon", -3.6845);
      expect(params).to.have.property("zoom", 16);
    });

    it("sets lat/lon from OSM.home", function () {
      OSM.home = { lat: 57.6247, lon: -3.6845 };
      const params = OSM.mapParams("?");
      expect(params).to.have.property("lat", 57.6247);
      expect(params).to.have.property("lon", -3.6845);
    });

    it("sets bbox from OSM.location", function () {
      OSM.location = { minlon: -3.6845, minlat: 57.6247, maxlon: -3.7845, maxlat: 57.7247 };
      const expected = L.latLngBounds([57.6247, -3.6845], [57.7247, -3.7845]);
      const params = OSM.mapParams("?");
      expect(params).to.have.property("bounds").deep.equal(expected);
    });

    it("parses params from the _osm_location cookie", function () {
      document.cookie = "_osm_location=-3.6845|57.6247|5|M";
      const params = OSM.mapParams("?");
      expect(params).to.have.property("lat", 57.6247);
      expect(params).to.have.property("lon", -3.6845);
      expect(params).to.have.property("zoom", 5);
      expect(params).to.have.property("layers", "M");
    });

    it("defaults lat/lon to London", function () {
      let params = OSM.mapParams("?");
      expect(params).to.have.property("lat", 51.5);
      expect(params).to.have.property("lon", -0.1);
      expect(params).to.have.property("zoom", 5);

      params = OSM.mapParams("?zoom=10");
      expect(params).to.have.property("lat", 51.5);
      expect(params).to.have.property("lon", -0.1);
      expect(params).to.have.property("zoom", 10);
    });

    it("parses layers param", function () {
      let params = OSM.mapParams("?");
      expect(params).to.have.property("layers", "");

      document.cookie = "_osm_location=-3.6845|57.6247|5|C";
      params = OSM.mapParams("?");
      expect(params).to.have.property("layers", "C");

      location.hash = "#map=5/57.6247/-3.6845&layers=M";
      params = OSM.mapParams("?");
      expect(params).to.have.property("layers", "M");
    });
  });

  describe(".parseHash", function () {
    it("parses lat/lon/zoom params", function () {
      const args = OSM.parseHash("#map=5/57.6247/-3.6845&layers=M");
      expect(args).to.have.property("center").deep.equal(L.latLng(57.6247, -3.6845));
      expect(args).to.have.property("zoom", 5);
    });

    it("parses layers params", function () {
      const args = OSM.parseHash("#map=5/57.6247/-3.6845&layers=M");
      expect(args).to.have.property("layers", "M");
    });
  });

  describe(".formatHash", function () {
    it("formats lat/lon/zoom params", function () {
      const args = { center: L.latLng(57.6247, -3.6845), zoom: 9 };
      expect(OSM.formatHash(args)).to.eq("#map=9/57.625/-3.685");
    });

    it("respects zoomPrecision", function () {
      let args = { center: L.latLng(57.6247, -3.6845), zoom: 5 };
      expect(OSM.formatHash(args)).to.eq("#map=5/57.62/-3.68");


      args = { center: L.latLng(57.6247, -3.6845), zoom: 9 };
      expect(OSM.formatHash(args)).to.eq("#map=9/57.625/-3.685");


      args = { center: L.latLng(57.6247, -3.6845), zoom: 12 };
      expect(OSM.formatHash(args)).to.eq("#map=12/57.6247/-3.6845");
    });

    it("formats layers params", function () {
      const args = { center: L.latLng(57.6247, -3.6845), zoom: 9, layers: "C" };
      expect(OSM.formatHash(args)).to.eq("#map=9/57.625/-3.685&layers=C");
    });

    it("ignores default layers", function () {
      const args = { center: L.latLng(57.6247, -3.6845), zoom: 9, layers: "M" };
      expect(OSM.formatHash(args)).to.eq("#map=9/57.625/-3.685");
    });
  });


  describe(".zoomPrecision", function () {
    it("suggests 1 digit for z0-2", function () {
      expect(OSM.zoomPrecision(0)).to.eq(1);
      expect(OSM.zoomPrecision(1)).to.eq(1);
      expect(OSM.zoomPrecision(2)).to.eq(1);
    });

    it("suggests 2 digits for z3-6", function () {
      expect(OSM.zoomPrecision(3)).to.eq(2);
      expect(OSM.zoomPrecision(4)).to.eq(2);
      expect(OSM.zoomPrecision(5)).to.eq(2);
      expect(OSM.zoomPrecision(6)).to.eq(2);
    });

    it("suggests 3 digits for z7-9", function () {
      expect(OSM.zoomPrecision(7)).to.eq(3);
      expect(OSM.zoomPrecision(8)).to.eq(3);
      expect(OSM.zoomPrecision(9)).to.eq(3);
    });

    it("suggests 4 digits for z10-12", function () {
      expect(OSM.zoomPrecision(10)).to.eq(4);
      expect(OSM.zoomPrecision(11)).to.eq(4);
      expect(OSM.zoomPrecision(12)).to.eq(4);
    });

    it("suggests 5 digits for z13-16", function () {
      expect(OSM.zoomPrecision(13)).to.eq(5);
      expect(OSM.zoomPrecision(14)).to.eq(5);
      expect(OSM.zoomPrecision(15)).to.eq(5);
      expect(OSM.zoomPrecision(16)).to.eq(5);
    });

    it("suggests 6 digits for z17-19", function () {
      expect(OSM.zoomPrecision(17)).to.eq(6);
      expect(OSM.zoomPrecision(18)).to.eq(6);
      expect(OSM.zoomPrecision(19)).to.eq(6);
    });

    it("suggests 7 digits for z20", function () {
      expect(OSM.zoomPrecision(20)).to.eq(7);
    });
  });

  describe(".locationCookie", function () {
    it("creates a location cookie value", function () {
      $("body").html($("<div id='map'>"));
      const map = new L.OSM.Map("map", { center: [57.6247, -3.6845], zoom: 9 });
      map.updateLayers("");
      expect(OSM.locationCookie(map)).to.eq("-3.685|57.625|9|M");
    });

    it("respects zoomPrecision", function () {
      $("body").html($("<div id='map'>"));
      const map = new L.OSM.Map("map", { center: [57.6247, -3.6845], zoom: 9 });
      map.updateLayers("");
      expect(OSM.locationCookie(map)).to.eq("-3.685|57.625|9|M");
      // map.setZoom() doesn't update the zoom level for some reason
      // using map._zoom here to update the zoom level manually
      map._zoom = 5;
      expect(OSM.locationCookie(map)).to.eq("-3.68|57.62|5|M");
    });
  });

  describe(".distance", function () {
    it("computes distance between points", function () {
      const latlng1 = L.latLng(51.76712, -0.00484),
            latlng2 = L.latLng(51.7675159, -0.0078329);

      expect(OSM.distance(latlng1, latlng2)).to.be.closeTo(210.664, 0.005);
      expect(OSM.distance(latlng2, latlng1)).to.be.closeTo(210.664, 0.005);
    });
  });
});
