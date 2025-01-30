//= require qs/dist/qs

OSM.initializeContextMenu = function (map) {
  map.contextmenu.addItem({
    text: I18n.t("javascripts.context.directions_from"),
    callback: function directionsFromHere(e) {
      const latlng = OSM.cropLocation(e.latlng, map.getZoom());

      OSM.router.route("/directions?" + Qs.stringify({
        from: latlng.join(","),
        to: getDirectionsEndpointCoordinatesFromInput($("#route_to"))
      }));
    }
  });

  map.contextmenu.addItem({
    text: I18n.t("javascripts.context.directions_to"),
    callback: function directionsToHere(e) {
      const latlng = OSM.cropLocation(e.latlng, map.getZoom());

      OSM.router.route("/directions?" + Qs.stringify({
        from: getDirectionsEndpointCoordinatesFromInput($("#route_from")),
        to: latlng.join(",")
      }));
    }
  });

  map.contextmenu.addItem({
    text: I18n.t("javascripts.context.add_note"),
    callback: function addNoteHere(e) {
      const [lat, lon] = OSM.cropLocation(e.latlng, map.getZoom());

      OSM.router.route("/note/new?" + Qs.stringify({ lat, lon }));
    }
  });

  map.contextmenu.addItem({
    text: I18n.t("javascripts.context.show_address"),
    callback: function describeLocation(e) {
      const [lat, lon] = OSM.cropLocation(e.latlng, map.getZoom()).map(encodeURIComponent);

      OSM.router.route("/search?" + Qs.stringify({ lat, lon }));
    }
  });

  map.contextmenu.addItem({
    text: I18n.t("javascripts.context.query_features"),
    callback: function queryFeatures(e) {
      const [lat, lon] = OSM.cropLocation(e.latlng, map.getZoom());

      OSM.router.route("/query?" + Qs.stringify({ lat, lon }));
    }
  });

  map.contextmenu.addItem({
    text: I18n.t("javascripts.context.centre_map"),
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
    } else {
      return $(input).val();
    }
  }

  var updateMenu = function updateMenu() {
    map.contextmenu.setDisabled(2, map.getZoom() < 12);
    map.contextmenu.setDisabled(4, map.getZoom() < 14);
  };

  map.on("zoomend", updateMenu);
  updateMenu();
};
