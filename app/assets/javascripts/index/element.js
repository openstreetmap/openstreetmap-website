(function () {
  $(document).on("click", "a[href='#versions-navigation-active-page-item']", function (e) {
    scrollToActiveVersion();
    $("#versions-navigation-active-page-item a.page-link").trigger("focus");
    e.preventDefault();
  });

  OSM.Element = function (map, type) {
    const page = {};
    let scrollStartObserver, scrollEndObserver;

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
      scrollToActiveVersion();

      const $scrollableList = $("#versions-navigation-list-middle");
      const [scrollableFirstItem] = $scrollableList.children().first();
      const [scrollableLastItem] = $scrollableList.children().last();

      if (scrollableFirstItem) {
        scrollStartObserver = createScrollObserver("#versions-navigation-list-start", "2px 0px");
        scrollStartObserver.observe(scrollableFirstItem);
      }

      if (scrollableLastItem) {
        scrollEndObserver = createScrollObserver("#versions-navigation-list-end", "-2px 0px");
        scrollEndObserver.observe(scrollableLastItem);
      }
    }

    function createScrollObserver(shadowTarget, shadowOffset) {
      const threshold = 0.95;
      return new IntersectionObserver(([entry]) => {
        const floating = entry.intersectionRatio < threshold;
        $(shadowTarget)
          .css("box-shadow", floating ? `rgba(0, 0, 0, 0.075) ${shadowOffset} 2px` : "")
          .css("z-index", floating ? "5" : ""); // floating z-index should be larger than z-index of Bootstrap's .page-link:focus, which is 3
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

  function scrollToActiveVersion() {
    const [scrollableList] = $("#versions-navigation-list-middle");

    if (!scrollableList) return;

    const [activeStartItem] = $("#versions-navigation-list-start #versions-navigation-active-page-item");
    const [activeScrollableItem] = $("#versions-navigation-list-middle #versions-navigation-active-page-item");

    if (activeStartItem) {
      scrollableList.scrollLeft = 0;
    } else if (activeScrollableItem) {
      scrollableList.scrollLeft = Math.round(activeScrollableItem.offsetLeft - (scrollableList.offsetWidth / 2) + (activeScrollableItem.offsetWidth / 2));
    } else {
      scrollableList.scrollLeft = scrollableList.scrollWidth - scrollableList.offsetWidth;
    }
  }
}());
