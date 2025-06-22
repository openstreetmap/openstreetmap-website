(function () {
  OSM.OldBrowse = function () {
    const page = {};

    page.pushstate = page.popstate = function (path) {
      OSM.loadSidebarContent(path);
    };

    return page;
  };

  OSM.Browse = function (map, type) {
    const page = {};

    page.pushstate = page.popstate = function (path, id, version) {
      OSM.loadSidebarContent(path, function () {
        addObject(type, id, version);
      });
    };

    page.load = function (path, id, version) {
      addObject(type, id, version, true);
    };

    function addObject(type, id, version, center) {
      const hashParams = OSM.parseHash();
      map.addObject({ type: type, id: parseInt(id, 10), version: version && parseInt(version, 10) }, function (bounds) {
        if (!hashParams.center && bounds.isValid() &&
            (center || !map.getBounds().contains(bounds))) {
          OSM.router.withoutMoveListener(function () {
            map.fitBounds(bounds);
          });
        }
      });
    }

    page.unload = function () {
      map.removeObject();
    };

    return page;
  };
}());
