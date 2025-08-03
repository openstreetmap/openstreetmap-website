//= require download_util

L.OSM.share = function (options) {
  const control = L.OSM.sidebarPane(options, "share", "javascripts.share.title", "javascripts.share.title"),
        marker = L.marker([0, 0], { draggable: true, icon: OSM.getMarker({ color: "var(--marker-blue)" }) }),
        locationFilter = new L.LocationFilter({
          enableButton: false,
          adjustButton: false
        });

  function init(map, $ui) {
    // Link / Embed

    $ui.find("#link_marker").on("change", toggleMarker);

    $ui.find(".btn-group .btn")
      .on("shown.bs.tab", () => {
        $ui.find(".tab-pane.active [id]")
          .trigger("select");
      });

    $ui.find(".share-tab [id]").on("click", select);

    // Image

    $ui.find("#mapnik_scale").on("change", update);

    $ui.find("#image_filter").bind("change", toggleFilter);

    const csrfInput = $ui.find("#csrf_export")[0];
    [[csrfInput.name, csrfInput.value]] = Object.entries(OSM.csrf);

    document.getElementById("export-image")
      .addEventListener("turbo:submit-end",
                        OSM.getTurboBlobHandler(OSM.i18n.t("javascripts.share.filename")));

    document.getElementById("export-image")
      .addEventListener("turbo:before-fetch-response", OSM.turboHtmlResponseHandler);

    locationFilter
      .on("change", update)
      .addTo(map);

    marker.on("dragend", movedMarker);
    map.on("move", movedMap);
    map.on("moveend baselayerchange overlayadd overlayremove", update);

    $ui
      .on("show", shown)
      .on("hide", hidden);

    update();

    function shown() {
      $("#mapnik_scale").val(getScale());
      update();
    }

    function hidden() {
      map.removeLayer(marker);
      map.options.scrollWheelZoom = map.options.doubleClickZoom = true;
      locationFilter.disable();
      update();
    }

    function toggleMarker() {
      if ($(this).is(":checked")) {
        marker.setLatLng(map.getCenter());
        map.addLayer(marker);
        map.options.scrollWheelZoom = map.options.doubleClickZoom = "center";
      } else {
        map.removeLayer(marker);
        map.options.scrollWheelZoom = map.options.doubleClickZoom = true;
      }
      update();
    }

    function toggleFilter() {
      if ($(this).is(":checked")) {
        locationFilter.setBounds(map.getBounds().pad(-0.2));
        locationFilter.enable();
      } else {
        locationFilter.disable();
      }
      update();
    }

    function movedMap() {
      marker.setLatLng(map.getCenter());
      update();
    }

    function movedMarker() {
      if (map.hasLayer(marker)) {
        map.off("move", movedMap);
        map.on("moveend", updateOnce);
        map.panTo(marker.getLatLng());
      }
    }

    function updateOnce() {
      map.off("moveend", updateOnce);
      map.on("move", movedMap);
      update();
    }

    function escapeHTML(string) {
      const htmlEscapes = {
        "&": "&amp;",
        "<": "&lt;",
        ">": "&gt;",
        "\"": "&quot;",
        "'": "&#x27;"
      };
      return string === null ? "" : String(string).replace(/[&<>"']/g, function (match) {
        return htmlEscapes[match];
      });
    }

    function update() {
      const layer = map.getMapBaseLayer();
      const canEmbed = Boolean(layer && layer.options.canEmbed);
      let bounds = map.getBounds();

      $("#link_marker")
        .prop("checked", map.hasLayer(marker));

      $("#image_filter")
        .prop("checked", locationFilter.isEnabled());

      // Link / Embed

      $("#short_input").val(map.getShortUrl(marker));
      $("#long_input").val(map.getUrl(marker));
      $("#short_link").attr("href", map.getShortUrl(marker));
      $("#long_link").attr("href", map.getUrl(marker));

      const params = new URLSearchParams({
        bbox: bounds.toBBoxString(),
        layer: map.getMapBaseLayerId()
      });

      if (map.hasLayer(marker)) {
        const latLng = marker.getLatLng().wrap();
        params.set("marker", latLng.lat + "," + latLng.lng);
      }

      if (!canEmbed && $("#nav-embed").hasClass("active")) {
        bootstrap.Tab.getOrCreateInstance($("#long_link")).show();
      }
      $("#embed_link")
        .toggleClass("disabled", !canEmbed)
        .parent()
        .tooltip(canEmbed ? "disable" : "enable");

      $("#embed_html").val(
        "<iframe width=\"425\" height=\"350\" src=\"" +
          escapeHTML(OSM.SERVER_PROTOCOL + "://" + OSM.SERVER_URL + "/export/embed.html?" + params) +
          "\" style=\"border: 1px solid black\"></iframe><br/>" +
          "<small><a href=\"" + escapeHTML(map.getUrl(marker)) + "\">" +
          escapeHTML(OSM.i18n.t("javascripts.share.view_larger_map")) + "</a></small>");

      // Geo URI

      $("#geo_uri")
        .attr("href", map.getGeoUri(marker))
        .text(map.getGeoUri(marker));

      // Image

      if (locationFilter.isEnabled()) {
        bounds = locationFilter.getBounds();
      }

      let scale = $("#mapnik_scale").val();
      const size = L.bounds(L.CRS.EPSG3857.project(bounds.getSouthWest()),
                            L.CRS.EPSG3857.project(bounds.getNorthEast())).getSize(),
            maxScale = Math.floor(Math.sqrt(size.x * size.y / 0.3136));

      $("#mapnik_minlon").val(bounds.getWest());
      $("#mapnik_minlat").val(bounds.getSouth());
      $("#mapnik_maxlon").val(bounds.getEast());
      $("#mapnik_maxlat").val(bounds.getNorth());

      if (scale < maxScale) {
        scale = roundScale(maxScale);
        $("#mapnik_scale").val(scale);
      }

      const mapWidth = Math.round(size.x / scale / 0.00028);
      const mapHeight = Math.round(size.y / scale / 0.00028);
      $("#mapnik_image_width").text(mapWidth);
      $("#mapnik_image_height").text(mapHeight);

      const canDownloadImage = Boolean(layer && layer.options.canDownloadImage);

      $("#mapnik_image_layer").text(canDownloadImage ? layer.options.name : "");
      $("#map_format").val(canDownloadImage ? layer.options.layerId : "");

      $("#map_zoom").val(map.getZoom());
      $("#mapnik_lon").val(map.getCenter().lng);
      $("#mapnik_lat").val(map.getCenter().lat);
      $("#map_width").val(mapWidth);
      $("#map_height").val(mapHeight);

      $("#export-image").toggle(canDownloadImage);
      $("#export-warning").toggle(!canDownloadImage);
      $("#mapnik_scale_row").toggle(canDownloadImage && layer.options.layerId === "mapnik");
    }

    function select() {
      $(this).trigger("select");
    }

    function getScale() {
      const bounds = map.getBounds(),
            centerLat = bounds.getCenter().lat,
            halfWorldMeters = 6378137 * Math.PI * Math.cos(centerLat * Math.PI / 180),
            meters = halfWorldMeters * (bounds.getEast() - bounds.getWest()) / 180,
            pixelsPerMeter = map.getSize().x / meters,
            metersPerPixel = 1 / (92 * 39.3701);
      return Math.round(1 / (pixelsPerMeter * metersPerPixel));
    }

    function roundScale(scale) {
      const precision = 5 * Math.pow(10, Math.floor(Math.LOG10E * Math.log(scale)) - 2);
      return precision * Math.ceil(scale / precision);
    }
  }

  control.onAddPane = function (map, button, $ui) {
    $("#content").addClass("overlay-right-sidebar");

    control.onContentLoaded = () => init(map, $ui);
    $ui.one("show", control.loadContent);
  };

  return control;
};
