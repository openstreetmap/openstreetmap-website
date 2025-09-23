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
};
