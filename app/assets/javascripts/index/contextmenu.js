OSM.initializeContextMenu = function (map) {
  map.contextmenu.addItem({
    text: OSM.i18n.t("javascripts.context.directions_from"),
    callback: function directionsFromHere(e) {
      const latlng = OSM.cropLocation(e.latlng, map.getZoom());

      OSM.router.route("/directions?" + new URLSearchParams({
        from: latlng.join(","),
        to: getDirectionsEndpointCoordinatesFromInput($("#route_to"))
      }));
    }
  });

  map.contextmenu.addItem({
    text: OSM.i18n.t("javascripts.context.directions_to"),
    callback: function directionsToHere(e) {
      const latlng = OSM.cropLocation(e.latlng, map.getZoom());

      OSM.router.route("/directions?" + new URLSearchParams({
        from: getDirectionsEndpointCoordinatesFromInput($("#route_from")),
        to: latlng.join(",")
      }));
    }
  });

  map.contextmenu.addItem({
    text: OSM.i18n.t("javascripts.context.add_note"),
    callback: function addNoteHere(e) {
      const [lat, lon] = OSM.cropLocation(e.latlng, map.getZoom());

      OSM.router.route("/note/new?" + new URLSearchParams({ lat, lon }));
    }
  });

  map.contextmenu.addItem({
    text: OSM.i18n.t("javascripts.context.show_address"),
    callback: function describeLocation(e) {
      const [lat, lon] = OSM.cropLocation(e.latlng, map.getZoom());

      OSM.router.route("/search?" + new URLSearchParams({ lat, lon }));
    }
  });

  map.contextmenu.addItem({
    text: OSM.i18n.t("javascripts.context.query_features"),
    callback: function queryFeatures(e) {
      const [lat, lon] = OSM.cropLocation(e.latlng, map.getZoom());

      OSM.router.route("/query?" + new URLSearchParams({ lat, lon }));
    }
  });

  map.contextmenu.addItem({
    text: OSM.i18n.t("javascripts.context.centre_map"),
    callback: function centreMap(e) {
      map.panTo(e.latlng);
    }
  });

  map.on("mousedown", function (e) {
    if (e.originalEvent.shiftKey) map.contextmenu.disable();
    else map.contextmenu.enable();
  });

  function getDirectionsEndpointCoordinatesFromInput(input) {
    if (input.attr("data-lat") && input.attr("data-lon")) {
      return input.attr("data-lat") + "," + input.attr("data-lon");
    }
    return $(input).val();
  }

  const updateMenu = function updateMenu() {
    map.contextmenu.setDisabled(2, map.getZoom() < 12);
    map.contextmenu.setDisabled(4, map.getZoom() < 14);
  };

  map.on("zoomend", updateMenu);
  updateMenu();
};
