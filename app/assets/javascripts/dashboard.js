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
      rollEnabled: false,
      dragRotate: false,
      pitchWithRotate: false,
      bearingSnap: 180,
      maxPitch: 0,
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
    map.touchZoomRotate.disableRotation();
    map.keyboard.disableRotation();

    const markerObjects = $("[data-user]")
      .map(function () {
        const { lat, lon, color, description } = $(this).data("user");

        if (!lat || !lon) return null;
        const marker = OSM.MapLibre.getMarker({ icon: "dot", color })
          .setLngLat([lon, lat])
          .setPopup(OSM.MapLibre.getPopup(description))
          .addTo(map);

        return { marker, lat, lon };
      })
      .get();

    const updateZIndex = () => {
      for (const item of markerObjects) {
        item.currentY = map.project([item.lon, item.lat]).y;
      }

      markerObjects.sort((a, b) => a.currentY - b.currentY);

      for (const [index, item] of markerObjects.entries()) {
        item.marker.getElement().style.zIndex = index;
      }
    };

    if (markerObjects.length > 0) {
      map.on("move", updateZIndex);
      map.on("rotate", updateZIndex);
      map.on("pitch", updateZIndex);
      updateZIndex();
    }
  }
});
