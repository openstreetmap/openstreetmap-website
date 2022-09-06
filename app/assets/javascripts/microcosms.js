$(document).ready(function () {
  const params = $("#microcosm_map").data();
  const map = L.map("microcosm_map", {
    attributionControl: false,
    zoomControl: false
  });
  map.addLayer(new L.OSM.Mapnik());
  map.setView([params.lat, params.lon], params.zoom);
});
