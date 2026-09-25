//= require polyline_decoder

describe("OSM.decodePolyline", function () {
  it("decodes a precision-5 polyline into {lat, lng} objects", function () {
    const coords = [[38.5, -120.2], [40.7, -120.95]];
    const encoded = polyline.encode(coords, 5);
    const points = OSM.decodePolyline(encoded, { precision: 5 });
    expect(points).to.eql([
      { lat: 38.5, lng: -120.2 },
      { lat: 40.7, lng: -120.95 }
    ]);
  });

  it("honours a custom precision option", function () {
    const coords = [[38.5, -120.2], [40.7, -120.95]];
    const encoded = polyline.encode(coords, 6);
    const points = OSM.decodePolyline(encoded, { precision: 6 });
    expect(points).to.eql([
      { lat: 38.5, lng: -120.2 },
      { lat: 40.7, lng: -120.95 }
    ]);
  });

  it("returns an empty array for an empty string", function () {
    expect(OSM.decodePolyline("", { precision: 5 })).to.eql([]);
  });
});
