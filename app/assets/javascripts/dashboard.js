//= require leaflet.locate

$(function () {
  const defaultHomeZoom = 12;
  let map;

  if ($("#map").length) {
    map = L.map("map", {
      attributionControl: false,
      zoomControl: false
    }).addLayer(new L.OSM.Mapnik());

    const position = $("html").attr("dir") === "rtl" ? "topleft" : "topright";

    L.OSM.zoom({ position }).addTo(map);

    L.OSM.locate({ position }).addTo(map);

    if (OSM.home) {
      map.setView([OSM.home.lat, OSM.home.lon], defaultHomeZoom);
    } else {
      map.setView([0, 0], 0);
    }

    $("[data-user]").each(function () {
      const user = $(this).data("user");
      if (user.lon && user.lat) {
        L.marker([user.lat, user.lon], { icon: OSM.getMarker({ color: user.color }) }).addTo(map)
          .bindPopup(user.description, { minWidth: 200 });
      }
    });
  }
});
