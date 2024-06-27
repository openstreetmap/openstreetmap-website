OSM.Home = function (map) {
  var page = {};

  page.pushstate = page.popstate = page.load = function () {
    map.setSidebarOverlaid(true);
  };

  return page;
};
