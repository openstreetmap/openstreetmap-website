OSM.Browse = function (map, type) {
  const page = {};
  let scrollStartObserver, scrollEndObserver;

  $(document).on("click", "a[href='#versions-navigation-current-page-link']", function (e) {
    scrollToCurrentVersion();
    e.preventDefault();
  });

  page.pushstate = page.popstate = function (path, id, version) {
    OSM.loadSidebarContent(path, function () {
      initVersionsNavigation();
      addObject(type, id, version);
    });
  };

  page.load = function (path, id, version) {
    initVersionsNavigation();
    addObject(type, id, version, true);
  };

  function initVersionsNavigation() {
    scrollToCurrentVersion();

    const $scrollable = $("#versions-navigation-scrollable");
    const [scrollableFirstItem] = $scrollable.children().first();
    const [scrollableLastItem] = $scrollable.children().last();

    if (scrollableFirstItem) {
      scrollStartObserver = createScrollObserver("#versions-navigation-pinned-start", "2px 0px");
      scrollStartObserver.observe(scrollableFirstItem);
    }

    if (scrollableLastItem) {
      scrollEndObserver = createScrollObserver("#versions-navigation-pinned-end", "-2px 0px");
      scrollEndObserver.observe(scrollableLastItem);
    }
  }

  function scrollToCurrentVersion() {
    const [scrollable] = $("#versions-navigation-scrollable");
    const [activeItem] = $("#versions-navigation-current-page-link");

    if (scrollable && activeItem) {
      scrollable.scrollLeft = Math.round(activeItem.offsetLeft - (scrollable.offsetWidth / 2) + (activeItem.offsetWidth / 2));
    }
  }

  function createScrollObserver(shadowTarget, shadowOffset) {
    const threshold = 0.95;
    return new IntersectionObserver(([entry]) => {
      $(shadowTarget).css("box-shadow", entry.intersectionRatio < threshold ? `rgba(0, 0, 0, 0.075) ${shadowOffset} 2px` : "");
    }, { threshold });
  }

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
    scrollStartObserver?.disconnect();
    scrollStartObserver = null;
    scrollEndObserver?.disconnect();
    scrollEndObserver = null;
  };

  return page;
};

OSM.OldBrowse = function () {
  const page = {};

  page.pushstate = page.popstate = function (path) {
    OSM.loadSidebarContent(path);
  };

  return page;
};
