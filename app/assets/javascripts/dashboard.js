//= require maplibre/map

$(function () {
  let map;

  if ($("#map").length) {
    map = new OSM.MapLibre.SecondaryMap();

    const position = $("html").attr("dir") === "rtl" ? "top-left" : "top-right";
    const navigationControl = new OSM.MapLibre.NavigationControl();
    const geolocateControl = new OSM.MapLibre.GeolocateControl();
    map.addControl(new OSM.MapLibre.CombinedControlGroup([navigationControl, geolocateControl]), position);

    const markerObjects = $("[data-user]")
      .filter(function () {
        const { lat, lon } = $(this).data("user");
        return lat && lon;
      })
      .map(function () {
        const { lat, lon, color, description } = $(this).data("user");

        const marker = new OSM.MapLibre.Marker({ color })
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
