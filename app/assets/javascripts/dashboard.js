//= require maplibre.map
//= require maplibre.combinedcontrolgroup
//= require maplibre/dom_util

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

    const markerObjects = $("[data-user]")
      .filter(function () {
        const { lat, lon } = $(this).data("user");
        return lat && lon;
      })
      .map(function () {
        const { lat, lon, color, description } = $(this).data("user");

        const marker = OSM.MapLibre.getMarker({ icon: "dot", color })
          .setLngLat([lon, lat])
          .setPopup(new OSM.MapLibre.Popup().setHTML(description));

        return { marker, lat, lon };
      })
      .get();

    for (const item of markerObjects) {
      item.marker.addTo(map);
    }

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
