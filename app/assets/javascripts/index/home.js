OSM.Home = function (map) {
  const page = {};

  page.pushstate = page.popstate = page.load = function () {
    map.setSidebarOverlaid(true);
  };

  return page;
};
