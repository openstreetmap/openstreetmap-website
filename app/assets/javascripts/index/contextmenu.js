OSM.initializations.push(function (map) {
  const $contextMenu = $("#map-context-menu");
  map.osm_contextmenu = new OSM.ContextMenu(map, $contextMenu);

  const toggleMenuItem = ($element, enable) => {
    $element.toggleClass("disabled", !enable)
      .attr("aria-disabled", enable ? null : "true");
  };

  const updateContextMenuState = () => {
    const zoom = map.getZoom();
    toggleMenuItem($("#menu-action-add-note"), zoom >= 12);
    toggleMenuItem($("#menu-action-query-features"), zoom >= 14);
  };

  const getDirectionsCoordinates = ($input) => {
    const lat = $input.attr("data-lat");
    const lon = $input.attr("data-lon");
    if (lat && lon) return `${lat},${lon}`;
    return $input.val();
  };

  const latLngFromContext = () =>
    L.latLng($contextMenu.data("lat"), $contextMenu.data("lng"));

  const croppedLatLon = () =>
    OSM.cropLocation(latLngFromContext(), map.getZoom());

  const routeWithLatLon = (path, extraParams = {}) => {
    const [lat, lon] = croppedLatLon();
    OSM.router.route(`${path}?` + new URLSearchParams({ lat, lon, ...extraParams }));
  };

  const contextmenuItems = [
    {
      id: "menu-action-directions-from",
      icon: "bi-cursor",
      text: OSM.i18n.t("javascripts.context.directions_from"),
      callback: () => {
        const params = new URLSearchParams({
          from: croppedLatLon().join(","),
          to: getDirectionsCoordinates($("#route_to"))
        });
        OSM.router.route(`/directions?${params}`);
      }
    },
    {
      id: "menu-action-directions-to",
      icon: "bi-flag",
      text: OSM.i18n.t("javascripts.context.directions_to"),
      callback: () => {
        const params = new URLSearchParams({
          from: getDirectionsCoordinates($("#route_from")),
          to: croppedLatLon().join(",")
        });
        OSM.router.route(`/directions?${params}`);
      }
    },
    {
      separator: true
    },
    {
      id: "menu-action-add-note",
      icon: "bi-chat-square-text",
      text: OSM.i18n.t("javascripts.context.add_note"),
      callback: () => routeWithLatLon("/note/new")
    },
    {
      separator: true
    },
    {
      id: "menu-action-show-address",
      icon: "bi-compass",
      text: OSM.i18n.t("javascripts.context.show_address"),
      callback: () => routeWithLatLon("/search", { zoom: map.getZoom() })
    },
    {
      id: "menu-action-query-features",
      icon: "bi-question-lg",
      text: OSM.i18n.t("javascripts.context.query_features"),
      callback: () => routeWithLatLon("/query")
    },
    {
      id: "menu-action-centre-map",
      icon: "bi-crosshair",
      text: OSM.i18n.t("javascripts.context.centre_map"),
      callback: () => map.panTo(latLngFromContext())
    }
  ];

  map.on("contextmenu", function (e) {
    map.osm_contextmenu.show(e, contextmenuItems);
    updateContextMenuState();
  });

  map.on("show-contextmenu", function (data) {
    map.osm_contextmenu.show(data.event, data.items);
  });

  map.on("zoomend", updateContextMenuState);
});

class ContextMenu {
  constructor(map, $element) {
    this._map = map;
    this._$element = $element;
    this._popperInstance = null;

    this._map.on("click movestart", this.hide, this);
    $(document).on("click", (e) => {
      if (!$(e.target).closest(this._$element).length) {
        this.hide();
      }
    });
  }

  show(e, items) {
    e.originalEvent.preventDefault();
    e.originalEvent.stopPropagation();

    this._render(items);
    this._$element.removeClass("d-none");
    this._updatePopper(e);

    this._$element.data("lat", e.latlng.lat);
    this._$element.data("lng", e.latlng.lng);
  }

  hide() {
    this._$element.addClass("d-none");
    if (this._popperInstance) {
      this._popperInstance.destroy();
      this._popperInstance = null;
    }
  }

  _updatePopper(e) {
    const getVirtualReference = (x, y) => ({
      getBoundingClientRect: () => ({
        width: 0, height: 0, top: y, left: x, right: x, bottom: y
      })
    });

    if (this._popperInstance) {
      this._popperInstance.destroy();
      this._popperInstance = null;
    }

    const virtualReference = getVirtualReference(
      e.originalEvent.clientX,
      e.originalEvent.clientY
    );

    this._popperInstance = Popper.createPopper(virtualReference, this._$element.find(".dropdown-menu")[0], {
      placement: "bottom-start",
      strategy: "absolute",
      modifiers: [
        {
          name: "offset",
          options: {
            offset: [0, 0]
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
  }

  _render(items) {
    const $menuList = $("<ul>").addClass("dropdown-menu show shadow cm_dropdown_menu");

    items.forEach((item) => {
      const $menuItem = item.separator ?
        this._createSeparator() :
        this._createMenuItem(item);
      $menuList.append($menuItem);
    });

    this._$element.empty().append($menuList);
  }

  _createMenuItem(item) {
    const $icon = $("<i>").addClass(`bi ${item.icon}`).prop("ariaHidden", true);
    const $label = $("<span>").text(item.text);

    const $link = $("<a>")
      .addClass("dropdown-item d-flex align-items-center gap-3")
      .attr({ href: "#", id: item.id })
      .append($icon, $label)
      .on("click", (e) => {
        e.preventDefault();
        item.callback?.();
        this.hide();
      });

    return $("<li>").append($link);
  }

  _createSeparator() {
    return $("<li>").append($("<hr>").addClass("dropdown-divider"));
  }
}

OSM.ContextMenu = ContextMenu;
