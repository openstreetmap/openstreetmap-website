//= require maplibre.map
//= require maplibre.combinedcontrolgroup

$(function () {
  let map;

  if ($("#map").length) {
    map = new maplibregl.Map(OSM.MapLibre.defaultSecondaryMapOptions);

    const position = $("html").attr("dir") === "rtl" ? "top-left" : "top-right";
    const navigationControl = new maplibregl.NavigationControl({ showCompass: false });
    const geolocateControl = new maplibregl.GeolocateControl({
      positionOptions: {
        enableHighAccuracy: true
      },
      trackUserLocation: true
    });
    map.addControl(new OSM.MapLibre.CombinedControlGroup([navigationControl, geolocateControl]), position);
    map.touchZoomRotate.disableRotation();
    map.keyboard.disableRotation();

    $("[data-user]").each(function () {
      const user = $(this).data("user");
      if (user.lon && user.lat) {
        OSM.MapLibre.getMarker({ icon: "dot", color: user.color })
          .setLngLat([user.lon, user.lat])
          .setPopup(OSM.MapLibre.getPopup(user.description))
          .addTo(map);
      }
    });
  }
});
