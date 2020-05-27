$(document).ready(function () {
  var params = $("#microcosm_map").data();
  var map = L.map("microcosm_map", {
    attributionControl: false,
    zoomControl: false
  });
  map.addLayer(new L.OSM.Mapnik());
  map.setView([params.lat, params.lon], params.zoom);
});
