$(document).ready(function () {
  var map = L.map("map", {
    attributionControl: false,
    zoomControl: false
  }).addLayer(new L.OSM.Mapnik());

  L.OSM.zoom()
    .addTo(map);

  var userMarkers = []

  $("[data-user]").each(function () {
    var user = $(this).data('user');
    if (user.lon && user.lat) {
      userMarkers.push(
        L.marker([user.lat, user.lon], {icon: getUserIcon(user.icon)})
          .addTo(map)
          .bindPopup(user.description)
      );
    }
  });

  if (userMarkers.length > 0) {
    var userLayer = L.featureGroup(userMarkers);
    map.fitBounds(userLayer.getBounds());
  }
});
