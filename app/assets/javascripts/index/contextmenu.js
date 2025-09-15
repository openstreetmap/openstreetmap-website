OSM.initializeContextMenu = function (map) {
  const $contextMenu = $("#map-context-menu");
  const $menuList = $contextMenu.find(".dropdown-menu");

  const getDirectionsCoordinates = ($input) => {
    return $input.attr("data-lat") && $input.attr("data-lon") ?
      `${$input.attr("data-lat")},${$input.attr("data-lon")}` :
      $input.val();
  };

  const toggleMenuItem = ($element, enable) => {
    $element.toggleClass("disabled", !enable);
    if (enable) {
      $element.removeAttr("aria-disabled");
    } else {
      $element.attr("aria-disabled", "true");
    }
  };

  const updateContextMenuState = () => {
    const zoom = map.getZoom();
    toggleMenuItem($("#menu-action-add-note"), zoom >= 12);
    toggleMenuItem($("#menu-action-query-features"), zoom >= 14);
  };

  const latLngFromContext = () =>
    L.latLng($contextMenu.data("lat"), $contextMenu.data("lng"));

  const croppedLatLon = () =>
    OSM.cropLocation(latLngFromContext(), map.getZoom());

  // Event bindings
  map.on("zoomend", updateContextMenuState);
  map.on("click", () => $contextMenu.addClass("d-none"));
  map.on("movestart", () => $contextMenu.addClass("d-none"));

  $(document).on("click", (e) => {
    if (!$(e.target).closest($contextMenu).length) {
      $contextMenu.addClass("d-none");
    }
  });

  map.on("contextmenu", function (e) {
    e.originalEvent.preventDefault();
    $contextMenu.removeClass("d-none");

    const { x, y, absoluteX, absoluteY } = calculateContextMenuPosition(e);
    const { top, left, dropup, dropleft } = adjustContextMenuPosition($menuList[0], x, y, absoluteX, absoluteY);

    $contextMenu.css({ top: `${top}px`, left: `${left}px` });
    $contextMenu.toggleClass("dropup", dropup);
    $contextMenu.toggleClass("dropleft", dropleft);

    $contextMenu.data("lat", e.latlng.lat);
    $contextMenu.data("lng", e.latlng.lng);

    updateContextMenuState();
  });

  // Action handlers
  const actions = {
    "menu-action-directions-from": () => {
      OSM.router.route("/directions?" + new URLSearchParams({
        from: croppedLatLon().join(","),
        to: getDirectionsCoordinates($("#route_to"))
      }));
    },
    "menu-action-directions-to": () => {
      OSM.router.route("/directions?" + new URLSearchParams({
        from: getDirectionsCoordinates($("#route_from")),
        to: croppedLatLon().join(",")
      }));
    },
    "menu-action-add-note": () => {
      const [lat, lon] = croppedLatLon();
      OSM.router.route("/note/new?" + new URLSearchParams({ lat, lon }));
    },
    "menu-action-show-address": () => {
      const [lat, lon] = croppedLatLon();
      OSM.router.route("/search?" + new URLSearchParams({ lat, lon, zoom: map.getZoom() }));
    },
    "menu-action-query-features": () => {
      const [lat, lon] = croppedLatLon();
      OSM.router.route("/query?" + new URLSearchParams({ lat, lon }));
    },
    "menu-action-centre-map": () => {
      map.panTo(latLngFromContext());
    }
  };

  $.each(actions, (id, handler) => {
    $(`#${id}`).on("click", function (e) {
      e.preventDefault();
      handler();
      $contextMenu.addClass("d-none");
    });
  });

  // Utility functions
  function calculateContextMenuPosition(e) {
    const mapRect = map.getContainer().getBoundingClientRect();
    const contentRect = $("#content")[0].getBoundingClientRect();
    const point = map.latLngToContainerPoint(e.latlng);

    const x = mapRect.left + point.x - contentRect.left;
    const y = mapRect.top + point.y - contentRect.top;
    const absoluteX = mapRect.left + point.x;
    const absoluteY = mapRect.top + point.y;

    return { x, y, absoluteX, absoluteY };
  }

  function adjustContextMenuPosition(menu, x, y, absX, absY) {
    const rtl = document.documentElement.dir === "rtl";
    const h = menu.offsetHeight;
    const w = menu.offsetWidth;

    const flipVertically = absY + h > window.innerHeight && absY > h;
    let flipHorizontally;
    if (rtl) {
      flipHorizontally = absX - w < 0;
    } else {
      flipHorizontally = absX + w > window.innerWidth && absX > w;
    }

    let left;
    if (rtl) {
      left = flipHorizontally ? x + w : x;
    } else {
      left = flipHorizontally ? x - w : x;
    }

    return {
      top: flipVertically ? y - h : y,
      left: left,
      dropup: flipVertically,
      dropleft: flipHorizontally
    };
  }
};
