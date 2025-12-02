//= require maplibre.map
//= require maplibre.i18n
//= require maplibre.combinedcontrolgroup

$(function () {
  const defaultHomeZoom = 11;
  let map;

  if ($("#map").length) {
    map = new maplibregl.Map({
      container: "map",
      style: OSM.Mapnik,
      attributionControl: false,
      locale: OSM.MaplibreLocale,
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
    map.addControl(new OSM.CombinedControlGroup([navigationControl, geolocateControl]), position);

    $("[data-user]").each(function () {
      const user = $(this).data("user");
      if (user.lon && user.lat) {
        OSM.createMapLibreMarker({ icon: "dot", color: user.color })
          .setLngLat([user.lon, user.lat])
          .setPopup(OSM.createMapLibrePopup(user.description))
          .addTo(map);
      }
    });
  }
});
