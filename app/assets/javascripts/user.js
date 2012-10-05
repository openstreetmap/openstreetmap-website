$(document).ready(function () {
  var map = createMap("map");

  if (OSM.home) {
    setMapCenter(new OpenLayers.LonLat(OSM.home.lon, OSM.home.lat), 12);
  } else {
    setMapCenter(new OpenLayers.LonLat(0, 0), 0);
  }

  if ($("#map").hasClass("set_location")) {
    var marker;

    if (OSM.home) {
      marker = addMarkerToMap(new OpenLayers.LonLat(OSM.home.lon, OSM.home.lat));
    }

    map.events.register("click", map, function (e) {
      if ($('#updatehome').is(':checked')) {
        var lonlat = getEventPosition(e);

        $('#homerow').removeClass();
        $('#home_lat').val(lonlat.lat);
        $('#home_lon').val(lonlat.lon);

        if (marker) {
          removeMarkerFromMap(marker);
        }

        marker = addMarkerToMap(lonlat);
      }
    });
  } else {
    $("[data-user]").each(function () {
      var user = $(this).data('user');
      if (user.lon && user.lat) {
        var icon = OpenLayers.Marker.defaultIcon();
        icon.url = OpenLayers.Util.getImageLocation(user.icon);
        addMarkerToMap(new OpenLayers.LonLat(user.lon, user.lat), icon, user.description);
      }
    });
  }
});
