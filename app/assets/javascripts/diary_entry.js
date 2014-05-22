$(document).ready(function () {
  var marker, map;

  function setLocation(e) {
    $("#latitude").val(e.latlng.lat);
    $("#longitude").val(e.latlng.lng);

    if (marker) {
      map.removeLayer(marker);
    }

    marker = L.marker(e.latlng, {icon: getUserIcon()}).addTo(map)
      .bindPopup(I18n.t('diary_entry.edit.marker_text'));
  }

  $("#usemap").click(function (e) {
    e.preventDefault();

    $("#map").show();
    $("#usemap").hide();

    var params = $("#map").data();
    var centre = [params.lat, params.lon];
    var position = $('html').attr('dir') === 'rtl' ? 'topleft' : 'topright';

    map = L.map("map", {
      attributionControl: false,
      zoomControl: false
    }).addLayer(new L.OSM.Mapnik());

    L.OSM.zoom({position: position})
      .addTo(map);

    map.setView(centre, params.zoom);

    if ($("#latitude").val() && $("#longitude").val()) {
      marker = L.marker(centre, {icon: getUserIcon()}).addTo(map)
        .bindPopup(I18n.t('diary_entry.edit.marker_text'));
    }

    map.on("click", setLocation);
  });
});
