//= require @mapbox/polyline/src/polyline

OSM.decodePolyline = function (encoded, { precision }) {
  return polyline.decode(encoded, precision).map(([lat, lng]) => ({ lat, lng }));
};
