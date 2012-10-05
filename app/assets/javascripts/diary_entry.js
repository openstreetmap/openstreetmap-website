$(document).ready(function () {
  var marker;

  function setLocation(e) {
    closeMapPopup();

    var lonlat = getEventPosition(e);

    $("#latitude").val(lonlat.lat);
    $("#longitude").val(lonlat.lon);

    if (marker) {
      removeMarkerFromMap(marker);
    }

    marker = addMarkerToMap(lonlat, null, I18n.t('diary_entry.edit.marker_text'));
  }

  $("#usemap").click(function (e) {
    e.preventDefault();

    $("#map").show();
    $("#usemap").hide();

    var params = $("#map").data();
    var centre = new OpenLayers.LonLat(params.lon, params.lat);
    var map = createMap("map");

    setMapCenter(centre, params.zoom);

    if ($("#latitude").val() && $("#longitude").val()) {
      marker = addMarkerToMap(centre, null, I18n.t('diary_entry.edit.marker_text'));
    }

    map.events.register("click", map, setLocation);
  });
});
