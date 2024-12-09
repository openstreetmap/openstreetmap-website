//= require qs/dist/qs

OSM.initializeContextMenu = function (map) {
  map.contextmenu.addItem({
    text: I18n.t("javascripts.context.directions_from"),
    callback: function directionsFromHere(e) {
      var precision = OSM.zoomPrecision(map.getZoom()),
          latlng = e.latlng.wrap(),
          lat = latlng.lat.toFixed(precision),
          lng = latlng.lng.toFixed(precision);

      OSM.router.route("/directions?" + Qs.stringify({
        from: lat + "," + lng,
        to: getDirectionsEndpointCoordinatesFromInput($("#route_to"))
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

      OSM.router.route("/directions?" + Qs.stringify({
        from: getDirectionsEndpointCoordinatesFromInput($("#route_from")),
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

      OSM.router.route("/search?lat=" + encodeURIComponent(lat) + "&lon=" + encodeURIComponent(lng));
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

  const expiry = new Date();
  expiry.setYear(expiry.getFullYear() + 10);
  let selectedDarkModeFilter = Cookies.get("_osm_dark_mode_filter") || "brightness80";

  let darkModeMenuElements = $(map.contextmenu.addItem({
    separator: true
  }));

  const darkModeMenuItems = [
    {
      name: "brightness100",
      filter: "none"
    },
    {
      name: "brightness80",
      filter: "brightness(.8)"
    },
    {
      name: "brightness60",
      filter: "brightness(.6)"
    },
    {
      name: "invert",
      filter: "invert(.8) hue-rotate(180deg)"
    }
  ];
  darkModeMenuItems.forEach((menuItem) => {
    if (selectedDarkModeFilter === menuItem.name) {
      $(":root").css("--dark-mode-filter", menuItem.filter);
    }
    const darkModeMenuElement = $(map.contextmenu.addItem({
      text: I18n.t("javascripts.map.filters." + menuItem.name),
      callback: () => {
        selectedDarkModeFilter = menuItem.name;
        Cookies.set("_osm_dark_mode_filter", menuItem.name, { secure: true, expires: expiry, path: "/", samesite: "lax" });
        $(":root").css("--dark-mode-filter", menuItem.filter);
        updateDarkModeMenu();
      }
    }));
    darkModeMenuElement.prepend(
      $("<input type='radio' tabindex='-1' class='leaflet-contextmenu-icon pe-none'>")
        .data("filter", menuItem.name)
        .css("transform", "scale(80%)")
    );
    darkModeMenuElements = darkModeMenuElements.add(darkModeMenuElement);
  });

  const prefersDarkQuery = matchMedia("(prefers-color-scheme: dark)");
  L.DomEvent.on(prefersDarkQuery, "change", () => {
    updateDarkModeMenu();
  });
  updateDarkModeMenu();

  function updateDarkModeMenu() {
    darkModeMenuElements.toggle(prefersDarkQuery.matches);
    darkModeMenuElements.find("input[type='radio']").each(function () {
      $(this).prop("checked", $(this).data("filter") === selectedDarkModeFilter);
    });
  }

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
