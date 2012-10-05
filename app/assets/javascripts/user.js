$(document).ready(function () {
  var params = $("#map").data();
  var map = createMap("map");

  setMapCenter(new OpenLayers.LonLat(params.lon, params.lat), params.zoom);

  if ($("#map").hasClass("set_location")) {
    var marker;

    if (params.marker) {
      marker = addMarkerToMap(new OpenLayers.LonLat(params.lon, params.lat));
    }

    map.events.register("click", map, function (e) {
      closeMapPopup();

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
    addMarkerToMap(new OpenLayers.LonLat(params.lon, params.lat), null, params.marker.description);

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
