$(document).ready(function () {
  var map = createMap("map", {
    panZoomControl: true
  });

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
