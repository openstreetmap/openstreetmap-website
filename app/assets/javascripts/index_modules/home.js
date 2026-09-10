export default function (map) {
  let marker;

  function clearMarker() {
    if (marker) map.removeLayer(marker);
    marker = null;
  }

  const page = {};

  function show(panToHome) {
    map.setSidebarOverlaid(true);
    clearMarker();

    if (OSM.home) {
      if (panToHome) {
        OSM.router.withoutMoveListener(function () {
          map.setView(OSM.home, 15, { reset: true });
        });
      }
      marker = L.marker(OSM.home, {
        icon: OSM.getMarker({}),
        title: OSM.i18n.t("javascripts.home.marker_title")
      }).addTo(map);
    } else {
      $("#browse_status").html(
        $("<div class='m-2 alert alert-warning'>").text(
          OSM.i18n.t("javascripts.home.not_set")
        )
      );
    }
  }

  page.load = function () {
    show(true);
  };

  page.init = function () {
    show(!OSM.parseHash(location.hash).center);
  };

  page.unload = function () {
    clearMarker();
    $("#browse_status").empty();
  };

  return page;
}
