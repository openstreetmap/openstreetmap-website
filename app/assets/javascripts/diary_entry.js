$(function () {
  let marker, map;

  function setLocation(e) {
    const latlng = e.latlng.wrap();

    $("#latitude").val(latlng.lat);
    $("#longitude").val(latlng.lng);

    if (marker) {
      map.removeLayer(marker);
    }

    marker = L.marker(e.latlng, { icon: OSM.getUserIcon() }).addTo(map)
      .bindPopup(OSM.i18n.t("diary_entries.edit.marker_text"));
  }

  $("#usemap").click(function (e) {
    e.preventDefault();

    $("#map").show();
    $("#usemap").hide();

    const params = $("#map").data();
    const centre = [params.lat, params.lon];
    const position = $("html").attr("dir") === "rtl" ? "topleft" : "topright";

    map = L.map("map", {
      attributionControl: false,
      zoomControl: false
    }).addLayer(new L.OSM.Mapnik());

    L.OSM.zoom({ position: position })
      .addTo(map);

    map.setView(centre, params.zoom);

    if ($("#latitude").val() && $("#longitude").val()) {
      marker = L.marker(centre, { icon: OSM.getUserIcon() }).addTo(map)
        .bindPopup(OSM.i18n.t("diary_entries.edit.marker_text"));
    }

    map.on("click", setLocation);
  });
});
