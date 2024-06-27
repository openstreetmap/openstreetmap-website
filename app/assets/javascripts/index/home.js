OSM.Home = function (map) {
  var marker;

  function clearMarker() {
    if (marker) map.removeLayer(marker);
    marker = null;
  }

  var page = {};

  page.pushstate = page.popstate = page.load = function () {
    map.setSidebarOverlaid(true);
    clearMarker();

    OSM.router.withoutMoveListener(function () {
      map.setView(OSM.home, 15, { reset: true });
    });
    marker = L.marker(OSM.home, {
      icon: OSM.getUserIcon(),
      title: I18n.t("javascripts.home.marker_title")
    }).addTo(map);
  };

  page.unload = function () {
    clearMarker();
  };

  return page;
};
