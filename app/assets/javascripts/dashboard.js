//= require maplibre.map
//= require maplibre.i18n
//= require maplibre.combinedcontrolgroup

$(function () {
  const defaultHomeZoom = 11;
  let map;

  if ($("#map").length) {
    map = new maplibregl.Map({
      container: "map",
      style: OSM.MapLibre.Styles.Mapnik,
      attributionControl: false,
      locale: OSM.MapLibre.Locale,
      center: OSM.home ? [OSM.home.lon, OSM.home.lat] : [0, 0],
      zoom: OSM.home ? defaultHomeZoom : 0
    });

    const position = $("html").attr("dir") === "rtl" ? "top-left" : "top-right";
    const navigationControl = new maplibregl.NavigationControl({ showCompass: false });
    const geolocateControl = new maplibregl.GeolocateControl({
      positionOptions: {
        enableHighAccuracy: true
      },
      trackUserLocation: true
    });
    map.addControl(new OSM.MapLibre.CombinedControlGroup([navigationControl, geolocateControl]), position);

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
