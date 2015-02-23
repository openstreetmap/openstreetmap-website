//= require leaflet
//= require leaflet.osm

window.onload = function () {
  var query = (window.location.search || '?').substr(1),
      args  = {};

  var pairs = query.split('&');
  for (var i = 0; i < pairs.length; i++) {
    var parts = pairs[i].split('=');
    args[parts[0]] = decodeURIComponent(parts[1] || '');
  }

  var map = L.map("map");
  map.attributionControl.setPrefix('');

  if (!args.layer || args.layer === "mapnik" || args.layer === "osmarender") {
    new L.OSM.Mapnik().addTo(map);
  } else if (args.layer === "cyclemap" || args.layer === "cycle map") {
    new L.OSM.CycleMap().addTo(map);
  } else if (args.layer === "transportmap") {
    new L.OSM.TransportMap().addTo(map);
  } else if (args.layer === "mapquest") {
    new L.OSM.MapQuestOpen().addTo(map);
  } else if (args.layer === "hot") {
    new L.OSM.HOT().addTo(map);
  }

  if (args.marker) {
    L.marker(args.marker.split(','), {icon: L.icon({
      iconUrl: OSM.MARKER_ICON,
      iconSize: new L.Point(25, 41),
      iconAnchor: new L.Point(12, 41),
      shadowUrl: OSM.MARKER_SHADOW,
      shadowSize: new L.Point(41, 41)
    })}).addTo(map);
  }

  if (args.bbox) {
    var bbox = args.bbox.split(',');
    map.fitBounds([L.latLng(bbox[1], bbox[0]),
                   L.latLng(bbox[3], bbox[2])]);
  } else {
    map.fitWorld();
  }
};
