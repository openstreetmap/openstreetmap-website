$(document).ready(function () {
  var map = createMap("map");

  if (OSM.home) {
    map.setView([OSM.home.lat, OSM.home.lon], 12);
  } else {
    map.setView([0, 0], 0);
  }

  if ($("#map").hasClass("set_location")) {
    var marker;

    if (OSM.home) {
      marker = addMarkerToMap([OSM.home.lat, OSM.home.lon]);
    }

    map.on("click", function (e) {
      if ($('#updatehome').is(':checked')) {
        $('#homerow').removeClass();
        $('#home_lat').val(e.latlng.lat);
        $('#home_lon').val(e.latlng.lng);

        if (marker) {
          removeMarkerFromMap(marker);
        }

        marker = addMarkerToMap(e.latlng);
      }
    });
  } else {
    $("[data-user]").each(function () {
      var user = $(this).data('user');
      if (user.lon && user.lat) {
        addMarkerToMap([user.lat, user.lon], L.icon({iconUrl: user.icon}), user.description);
      }
    });
  }
});
