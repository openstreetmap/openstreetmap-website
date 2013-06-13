$(document).ready(function () {
  var map = createMap("map", {
    panZoomControl: true
  });

  /* TODO: display bounding box of group members */
  map.setView([OSM.home.lat, OSM.home.lon], 12);

  $("[data-user]").each(function () {
    var user = $(this).data('user');
    if (user.lon && user.lat) {
      L.marker([user.lat, user.lon], {icon: getUserIcon(user.icon)}).addTo(map)
        .bindPopup(user.description);
    }
  });
});
