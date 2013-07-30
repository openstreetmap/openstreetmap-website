$(document).ready(function () {
  var map = L.map("map", {
    attributionControl: false,
    zoomControl: false
  }).addLayer(new L.OSM.Mapnik());

  L.OSM.zoom()
    .addTo(map);

  if (OSM.home) {
    map.setView([OSM.home.lat, OSM.home.lon], 12);
  } else {
    map.setView([0, 0], 0);
  }

  if ($("#map").hasClass("set_location")) {
    var marker = L.marker([0, 0], {icon: getUserIcon()});

    if (OSM.home) {
      marker.setLatLng([OSM.home.lat, OSM.home.lon]);
      marker.addTo(map);
    }

    map.on("click", function (e) {
      if ($('#updatehome').is(':checked')) {
        var zoom = map.getZoom(),
            toZoom = zoomPrecision(zoom),
            location = e.latlng.wrap();

        $('#homerow').removeClass();
        $('#home_lat').val(toZoom(location.lat));
        $('#home_lon').val(toZoom(location.lng));

        marker.setLatLng(e.latlng);
        marker.addTo(map);
      }
    });
  } else {
    $("[data-user]").each(function () {
      var user = $(this).data('user');
      if (user.lon && user.lat) {
        L.marker([user.lat, user.lon], {icon: getUserIcon(user.icon)}).addTo(map)
          .bindPopup(user.description);
      }
    });
  }
});
