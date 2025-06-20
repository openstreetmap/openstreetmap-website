OSM.Element = function (map, type) {
  const page = {};
  let scrollStartObserver, scrollEndObserver;

  $(document).on("click", "a[href='#versions-navigation-current-page-link']", function (e) {
    scrollToCurrentVersion();
    e.preventDefault();
  });

  page.pushstate = page.popstate = function (path, id, version) {
    OSM.loadSidebarContent(path, function () {
      initVersionsNavigation();
      page._addObject(type, id, version);
    });
  };

  page.load = function (path, id, version) {
    initVersionsNavigation();
    page._addObject(type, id, version, true);
  };

  page.unload = function () {
    page._removeObject();
    scrollStartObserver?.disconnect();
    scrollStartObserver = null;
    scrollEndObserver?.disconnect();
    scrollEndObserver = null;
  };

  page._addObject = function () {};
  page._removeObject = function () {};

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

    if (!scrollable) return;

    const [activeStartItem] = $("#versions-navigation-pinned-start #versions-navigation-current-page-link");
    const [activeScrollableItem] = $("#versions-navigation-scrollable #versions-navigation-current-page-link");
    const [activeEndItem] = $("#versions-navigation-pinned-end #versions-navigation-current-page-link");

    if (activeStartItem) {
      scrollable.scrollLeft = 0;
    }
    if (activeScrollableItem) {
      scrollable.scrollLeft = Math.round(activeScrollableItem.offsetLeft - (scrollable.offsetWidth / 2) + (activeScrollableItem.offsetWidth / 2));
    }
    if (activeEndItem) {
      scrollable.scrollLeft = scrollable.scrollWidth - scrollable.offsetWidth;
    }
  }

  function createScrollObserver(shadowTarget, shadowOffset) {
    const threshold = 0.95;
    return new IntersectionObserver(([entry]) => {
      $(shadowTarget).css("box-shadow", entry.intersectionRatio < threshold ? `rgba(0, 0, 0, 0.075) ${shadowOffset} 2px` : "");
    }, { threshold });
  }

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
