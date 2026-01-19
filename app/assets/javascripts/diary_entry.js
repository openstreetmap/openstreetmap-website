//= require maplibre.map
//= require maplibre/dom_util

$(function () {
  let marker, map;

  function updateFormFieldsFromMarkerPosition() {
    const lngLat = marker.getLngLat();
    $("#latitude").val(lngLat.lat);
    $("#longitude").val(lngLat.lng);
  }

  function setLocation(e) {
    const coords = e.lngLat.wrap();
    if (marker) {
      marker.setLngLat(coords);
    } else {
      marker = new OSM.MapLibre.Marker({ draggable: true })
        .setLngLat(coords)
        .setPopup(new OSM.MapLibre.Popup().setHTML(OSM.i18n.t("diary_entries.edit.marker_text")))
        .addTo(map);
      marker.on("dragend", updateFormFieldsFromMarkerPosition);
    }
    updateFormFieldsFromMarkerPosition();
  }

  $("#usemap").click(function (e) {
    e.preventDefault();

    $("#map").show();
    $("#usemap").hide();

    const params = $("#map").data();
    map = new maplibregl.Map({
      ...OSM.MapLibre.defaultSecondaryMapOptions,
      center: [params.lon, params.lat],
      zoom: params.zoom - 1
    });

    const position = $("html").attr("dir") === "rtl" ? "top-left" : "top-right";
    const navigationControl = new maplibregl.NavigationControl({ showCompass: false });
    map.addControl(navigationControl, position);
    map.touchZoomRotate.disableRotation();
    map.keyboard.disableRotation();

    // Create marker if coordinates exist when map is shown
    if ($("#latitude").val() && $("#longitude").val()) {
      const lngLat = new maplibregl.LngLat($("#longitude").val(), $("#latitude").val());
      setLocation({ lngLat });
      map.setCenter(lngLat);
    }

    map.on("click", setLocation);
  });
});
