(function () {
  OSM.Element = function (map, type) {
    const page = {};

    page.pushstate = page.popstate = function (path, id, version) {
      OSM.loadSidebarContent(path, function () {
        page._addObject(type, id, version);
      });
    };

    page.load = function (path, id, version) {
      page._addObject(type, id, version, true);
    };

    page.unload = function () {
      page._removeObject();
    };

    page._addObject = function () {};
    page._removeObject = function () {};

    return page;
  };

  OSM.MappedElement = function (map, type) {
    const page = OSM.Element(map, type);

    page._addObject = function (type, id, version, center) {
      const hashParams = OSM.parseHash();
      map.addObject({ type: type, id: parseInt(id, 10), version: version && parseInt(version, 10) }, function (bounds) {
        if (!hashParams.center && bounds.isValid() &&
            (center || !map.getBounds().contains(bounds))) {
          OSM.router.withoutMoveListener(function () {
            map.fitBounds(bounds);
          });
        }
      });
    };

    page._removeObject = function () {
      map.removeObject();
    };

    return page;
  };
}());
