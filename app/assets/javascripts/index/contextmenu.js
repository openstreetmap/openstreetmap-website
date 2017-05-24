OSM.initializeContextMenu = function (map) {
  map.contextmenu.addItem({
    text: I18n.t("javascripts.context.directions_from"),
    callback: function directionsFromHere(e) {
      var precision = OSM.zoomPrecision(map.getZoom()),
          latlng = e.latlng.wrap(),
          lat = latlng.lat.toFixed(precision),
          lng = latlng.lng.toFixed(precision);

      OSM.router.route("/directions?" + querystring.stringify({
        route: lat + "," + lng + ";" + $("#route_to").val()
      }));
    }
  });

  map.contextmenu.addItem({
    text: I18n.t("javascripts.context.directions_to"),
    callback: function directionsToHere(e) {
      var precision = OSM.zoomPrecision(map.getZoom()),
          latlng = e.latlng.wrap(),
          lat = latlng.lat.toFixed(precision),
          lng = latlng.lng.toFixed(precision);

      OSM.router.route("/directions?" + querystring.stringify({
        route: $("#route_from").val() + ";" + lat + "," + lng
      }));
    }
  });

  map.contextmenu.addItem({
    text: I18n.t("javascripts.context.add_note"),
    callback: function addNoteHere(e) {
      var precision = OSM.zoomPrecision(map.getZoom()),
          latlng = e.latlng.wrap(),
          lat = latlng.lat.toFixed(precision),
          lng = latlng.lng.toFixed(precision);

      OSM.router.route("/note/new?lat=" + lat + "&lon=" + lng);
    }
  });

  map.contextmenu.addItem({
    text: I18n.t("javascripts.context.show_address"),
    callback: function describeLocation(e) {
      var precision = OSM.zoomPrecision(map.getZoom()),
          latlng = e.latlng.wrap(),
          lat = latlng.lat.toFixed(precision),
          lng = latlng.lng.toFixed(precision);

      OSM.router.route("/search?query=" + encodeURIComponent(lat + "," + lng));
    }
  });

  map.contextmenu.addItem({
    text: I18n.t("javascripts.context.query_features"),
    callback: function queryFeatures(e) {
      var precision = OSM.zoomPrecision(map.getZoom()),
          latlng = e.latlng.wrap(),
          lat = latlng.lat.toFixed(precision),
          lng = latlng.lng.toFixed(precision);

      OSM.router.route("/query?lat=" + lat + "&lon=" + lng);
    }
  });

  map.contextmenu.addItem({
    text: I18n.t("javascripts.context.open_tile_image"),
    callback: function openTileImage(e) {
      for (var i = 0; i < map.baseLayers.length; i++) {
        if (map.hasLayer(map.baseLayers[i])) {
          var latlng = e.latlng.wrap(),
              pixel = map.project(latlng, map.getZoom()).floor(),
              tileSize = map.baseLayers[i].getTileSize(),
              coords = pixel.unscaleBy(tileSize).floor(),
              url = map.baseLayers[i].getTileUrl(coords);

          if (url)
            window.open(url);

          break;
        }
      }
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

  var updateMenu = function updateMenu () {
    map.contextmenu.setDisabled(2, map.getZoom() < 12);
    map.contextmenu.setDisabled(4, map.getZoom() < 14);
  };

  map.on("zoomend", updateMenu);
  updateMenu();
};
