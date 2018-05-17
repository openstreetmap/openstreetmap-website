OSM.initializeContextMenu = function (map) {
  map.contextmenu.addItem({
    text: I18n.t("javascripts.context.directions_from"),
    callback: function directionsFromHere(e) {
      var precision = OSM.zoomPrecision(map.getZoom()),
          latlng = e.latlng.wrap(),
          lat = latlng.lat.toFixed(precision),
          lng = latlng.lng.toFixed(precision);

      OSM.router.route("/directions?" + querystring.stringify({
        from: lat + "," + lng,
        to: $("#route_to").val()
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
        from: $("#route_from").val(),
        to: lat + "," + lng
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
    text: I18n.t("javascripts.context.centre_map"),
    callback: function centreMap(e) {
      map.panTo(e.latlng);
    }
  });

  if (OSM.user) {
    map.contextmenu.addItem({
      text: I18n.t("javascripts.context.set_home_location"),
      callback: function setHomeLocation(e) {
        var precision = OSM.zoomPrecision(map.getZoom()),
            latlng = e.latlng.wrap(),
            lat = latlng.lat.toFixed(precision),
            lng = latlng.lng.toFixed(precision);
        
        $.post({url: "/set_home_loc?lat=" + lat + "&lon=" + lng, success: function(){
          $('#homeanchor').data("lat", lat);
          $('#homeanchor').data("lon", lng);
          $('#homeanchor').click();
        }});
      }
    });
  }

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
