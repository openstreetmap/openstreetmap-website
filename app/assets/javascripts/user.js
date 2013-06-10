$(document).ready(function () {
  var map = L.map("map", {
    attributionControl: false,
    zoomControl: false
  }).addLayer(new L.OSM.Mapnik());

  L.control.zoom({position: 'topright'})
    .addTo(map);

  $("#map").on("resized", function () {
    map.invalidateSize();
  });

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
        $('#homerow').removeClass();
        $('#home_lat').val(e.latlng.lat);
        $('#home_lon').val(e.latlng.lng);

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
