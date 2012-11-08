$(document).ready(function () {
  var map = createMap("map", {
    zoomControl: true,
    panZoomControl: false
  });

  if (OSM.home) {
    map.setView([OSM.home.lat, OSM.home.lon], 12);
  } else {
    map.setView([0, 0], 0);
  }

  if ($("#map").hasClass("set_location")) {
    var marker;

    if (OSM.home) {
      marker = L.marker([OSM.home.lat, OSM.home.lon]).addTo(map);
    }

    map.on("click", function (e) {
      if ($('#updatehome').is(':checked')) {
        $('#homerow').removeClass();
        $('#home_lat').val(e.latlng.lat);
        $('#home_lon').val(e.latlng.lng);

        if (marker) {
          map.removeLayer(marker);
        }

        marker = L.marker(e.latlng).addTo(map);
      }
    });
  } else {
    $("[data-user]").each(function () {
      var user = $(this).data('user');
      if (user.lon && user.lat) {
        L.marker([user.lat, user.lon], {icon: L.icon({iconUrl: user.icon})}).addTo(map)
          .bindPopup(user.description);
      }
    });
  }
});
