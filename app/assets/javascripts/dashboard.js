$(function () {
  const defaultHomeZoom = 12;
  let map;

  if ($("#map").length) {
    map = new maplibregl.Map({
      container: "map",
      style: {
        version: 8,
        sources: {
          osm: {
            type: "raster",
            tiles: [
              "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
            ],
            tileSize: 256,
            maxzoom: 19,
          }
        },
        layers: [
          {
            id: "osm",
            type: "raster",
            source: "osm"
          }
        ]
      },
      attributionControl: false,
      center: OSM.home ? [OSM.home.lon, OSM.home.lat] : [0, 0],
      zoom: OSM.home ? defaultHomeZoom : 0
    });

    const position = $("html").attr("dir") === "rtl" ? "top-left" : "top-right";
    map.addControl(new maplibregl.NavigationControl({ showCompass: false }), position);
    const geolocate = new maplibregl.GeolocateControl({
      positionOptions: {
        enableHighAccuracy: true
      },
      trackUserLocation: true
    });
    map.addControl(geolocate, position);

    $("[data-user]").each(function () {
      const user = $(this).data("user");
      if (user.lon && user.lat) {
        const popup = new maplibregl.Popup()
          .setHTML(user.description);

        new maplibregl.Marker({ color: user.color })
          .setLngLat([user.lon, user.lat])
          .setPopup(popup)
          .addTo(map);
      }
    });
  }
});
