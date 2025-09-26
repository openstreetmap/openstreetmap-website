/* global Popper */

OSM.initializeContextMenu = function (map) {
  const $contextMenu = $("#map-context-menu");

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

  let popperInstance = null;

  map.on("contextmenu", function (e) {
    e.originalEvent.preventDefault();
    $contextMenu.removeClass("d-none");
    const contextMenu = document.querySelector("#map-context-menu .dropdown-menu");

    // Create a virtual element at the mouse position
    const virtualReference = {
      getBoundingClientRect: () => ({
        width: 0,
        height: 0,
        top: e.originalEvent.clientY,
        left: e.originalEvent.clientX,
        right: e.originalEvent.clientX,
        bottom: e.originalEvent.clientY
      }),
      contextElement: contextMenu
    };

    if (popperInstance) {
      popperInstance.destroy();
    }

    popperInstance = Popper.createPopper(virtualReference, contextMenu, {
      placement: "bottom-start",
      strategy: "absolute",
      modifiers: [
        {
          name: "offset",
          options: {
            offset: [0, 0] // no offset, exactly aligned to placement corner
          }
        },
        {
          name: "preventOverflow",
          options: { boundary: document.getElementById("map") }
        },
        {
          name: "flip",
          options: {
            fallbackPlacements: ["top-start", "bottom-end", "top-end"]
          }
        }
      ]
    });

    $contextMenu.data("lat", e.latlng.lat);
    $contextMenu.data("lng", e.latlng.lng);

    updateContextMenuState();
  });

  const getDirectionsCoordinates = ($input) => {
    return $input.attr("data-lat") && $input.attr("data-lon") ?
      `${$input.attr("data-lat")},${$input.attr("data-lon")}` :
      $input.val();
  };

  const contextmenuItems = [
    {
      id: "menu-action-directions-from",
      icon: "bi-geo-alt",
      text: OSM.i18n.t("javascripts.context.directions_from"),
      callback: () => {
        OSM.router.route("/directions?" + new URLSearchParams({
          from: croppedLatLon().join(","),
          to: getDirectionsCoordinates($("#route_to"))
        }));
      }
    },
    {
      id: "menu-action-directions-to",
      icon: "bi-flag",
      text: OSM.i18n.t("javascripts.context.directions_to"),
      callback: () => {
        OSM.router.route("/directions?" + new URLSearchParams({
          from: getDirectionsCoordinates($("#route_from")),
          to: croppedLatLon().join(",")
        }));
      }
    },
    {
      separator: true
    },
    {
      id: "menu-action-add-note",
      icon: "bi-pencil",
      text: OSM.i18n.t("javascripts.context.add_note"),
      callback: () => {
        const [lat, lon] = croppedLatLon();
        OSM.router.route("/note/new?" + new URLSearchParams({ lat, lon }));
      }
    },
    {
      separator: true
    },
    {
      id: "menu-action-show-address",
      icon: "bi-compass",
      text: OSM.i18n.t("javascripts.context.show_address"),
      callback: () => {
        const [lat, lon] = croppedLatLon();
        OSM.router.route("/search?" + new URLSearchParams({ lat, lon, zoom: map.getZoom() }));
      }
    },
    {
      id: "menu-action-query-features",
      icon: "bi-question-circle",
      text: OSM.i18n.t("javascripts.context.query_features"),
      callback: () => {
        const [lat, lon] = croppedLatLon();
        OSM.router.route("/query?" + new URLSearchParams({ lat, lon }));
      }
    },
    {
      id: "menu-action-centre-map",
      icon: "bi-crosshair",
      text: OSM.i18n.t("javascripts.context.centre_map"),
      callback: () => {
        map.panTo(latLngFromContext());
      }
    }
  ];

  OSM.renderContextMenu($contextMenu, contextmenuItems);
};

OSM.createSeparator = function () {
  return $("<li>").append(
    $("<hr>").addClass("dropdown-divider")
  );
};

OSM.createMenuItem = function (item, $contextMenu) {
  const $icon = $("<i>").addClass(`bi ${item.icon}`);
  const $label = $("<span>").text(item.text);

  const $link = $("<a>")
    .addClass("dropdown-item d-flex align-items-center gap-3")
    .attr({ href: "#", id: item.id })
    .append($icon, $label)
    .on("click", (e) => {
      e.preventDefault();
      item.callback?.();
      $contextMenu.addClass("d-none");
    });

  return $("<li>").append($link);
};

OSM.renderContextMenu = function ($contextMenu, contextmenuItems) {
  const $menuList = $("<ul>").addClass("dropdown-menu show shadow cm_dropdown_menu");

  contextmenuItems.forEach((item) => {
    const $menuItem = item.separator ?
      OSM.createSeparator() :
      OSM.createMenuItem(item, $contextMenu);
    $menuList.append($menuItem);
  });

  $contextMenu.empty().append($menuList);
};
