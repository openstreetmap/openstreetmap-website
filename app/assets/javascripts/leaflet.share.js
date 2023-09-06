L.OSM.share = function (options) {
  var control = L.OSM.sidebarPane(options, "share", "javascripts.share.title", "javascripts.share.title"),
      marker = L.marker([0, 0], { draggable: true }),
      locationFilter = new L.LocationFilter({
        enableButton: false,
        adjustButton: false
      });

  control.onAddPane = function (map, button, $ui) {
    // Link / Embed

    var $linkSection = $("<div>")
      .attr("class", "section share-link")
      .appendTo($ui);

    $("<h4>")
      .text(I18n.t("javascripts.share.link"))
      .appendTo($linkSection);

    var $form = $("<form>")
      .appendTo($linkSection);

    $("<div>")
      .attr("class", "form-check mb-3")
      .appendTo($form)
      .append($("<label>")
        .attr("for", "link_marker")
        .attr("class", "form-check-label")
        .text(I18n.t("javascripts.share.include_marker")))
      .append($("<input>")
        .attr("id", "link_marker")
        .attr("type", "checkbox")
        .attr("class", "form-check-input")
        .bind("change", toggleMarker));

    $("<div class='btn-group btn-group-sm mb-2'>")
      .appendTo($form)
      .append($("<a class='btn btn-primary'>")
        .addClass("active")
        .attr("for", "long_input")
        .attr("id", "long_link")
        .text(I18n.t("javascripts.share.long_link")))
      .append($("<a class='btn btn-primary'>")
        .attr("for", "short_input")
        .attr("id", "short_link")
        .text(I18n.t("javascripts.share.short_link")))
      .append($("<a class='btn btn-primary'>")
        .attr("for", "embed_html")
        .attr("href", "#")
        .text(I18n.t("javascripts.share.embed")))
      .on("click", "a", function (e) {
        e.preventDefault();
        var id = "#" + $(this).attr("for");
        $(this).siblings("a")
          .removeClass("active");
        $(this).addClass("active");
        $linkSection.find(".share-tab")
          .hide();
        $linkSection.find(".share-tab:has(" + id + ")")
          .show()
          .find("input, textarea")
          .select();
      });

    $("<div>")
      .attr("class", "share-tab")
      .appendTo($form)
      .append($("<input>")
        .attr("id", "long_input")
        .attr("type", "text")
        .attr("class", "form-control form-control-sm font-monospace")
        .attr("readonly", true)
        .on("click", select));

    $("<div>")
      .attr("class", "share-tab")
      .hide()
      .appendTo($form)
      .append($("<input>")
        .attr("id", "short_input")
        .attr("type", "text")
        .attr("class", "form-control form-control-sm font-monospace")
        .attr("readonly", true)
        .on("click", select));

    $("<div>")
      .attr("class", "share-tab")
      .hide()
      .appendTo($form)
      .append(
        $("<textarea>")
          .attr("id", "embed_html")
          .attr("class", "form-control form-control-sm font-monospace")
          .attr("readonly", true)
          .on("click", select))
      .append(
        $("<p>")
          .attr("class", "text-muted")
          .text(I18n.t("javascripts.share.paste_html")));

    // Geo URI

    var $geoUriSection = $("<div>")
      .attr("class", "section share-geo-uri")
      .appendTo($ui);

    $("<h4>")
      .text(I18n.t("javascripts.share.geo_uri"))
      .appendTo($geoUriSection);

    $("<div>")
      .appendTo($geoUriSection)
      .append($("<a>")
        .attr("id", "geo_uri"));

    // Image

    var $imageSection = $("<div>")
      .attr("class", "section share-image")
      .appendTo($ui);

    $("<h4>")
      .text(I18n.t("javascripts.share.image"))
      .appendTo($imageSection);

    $("<div>")
      .attr("id", "export-warning")
      .attr("class", "text-muted")
      .text(I18n.t("javascripts.share.only_standard_layer"))
      .appendTo($imageSection);

    $form = $("<form>")
      .attr("id", "export-image")
      .attr("action", "/export/finish")
      .attr("method", "post")
      .appendTo($imageSection);

    $("<div>")
      .appendTo($form)
      .attr("class", "row mb-3")
      .append($("<label>")
        .attr("for", "mapnik_format")
        .attr("class", "col-auto col-form-label")
        .text(I18n.t("javascripts.share.format")))
      .append($("<div>")
        .attr("class", "col-auto")
        .append($("<select>")
          .attr("name", "mapnik_format")
          .attr("id", "mapnik_format")
          .attr("class", "form-select w-auto")
          .append($("<option>").val("png").text("PNG").prop("selected", true))
          .append($("<option>").val("jpeg").text("JPEG"))
          .append($("<option>").val("svg").text("SVG"))
          .append($("<option>").val("pdf").text("PDF"))));

    $("<div>")
      .appendTo($form)
      .attr("class", "row mb-3")
      .append($("<label>")
        .attr("for", "mapnik_scale")
        .attr("class", "col-auto col-form-label")
        .text(I18n.t("javascripts.share.scale")))
      .append($("<div>")
        .attr("class", "col-auto")
        .append($("<div>")
          .attr("class", "input-group flex-nowrap")
          .append($("<span>")
            .attr("class", "input-group-text")
            .text("1 : "))
          .append($("<input>")
            .attr("name", "mapnik_scale")
            .attr("id", "mapnik_scale")
            .attr("type", "text")
            .attr("class", "form-control")
            .on("change", update))));

    $("<div>")
      .attr("class", "row mb-3")
      .appendTo($form)
      .append($("<div>")
        .attr("class", "col-auto")
        .append($("<div>")
          .attr("class", "form-check")
          .append($("<label>")
            .attr("for", "image_filter")
            .attr("class", "form-check-label")
            .text(I18n.t("javascripts.share.custom_dimensions")))
          .append($("<input>")
            .attr("id", "image_filter")
            .attr("type", "checkbox")
            .attr("class", "form-check-input")
            .bind("change", toggleFilter))));

    ["minlon", "minlat", "maxlon", "maxlat"].forEach(function (name) {
      $("<input>")
        .attr("id", "mapnik_" + name)
        .attr("name", name)
        .attr("type", "hidden")
        .appendTo($form);
    });

    $("<input>")
      .attr("name", "format")
      .attr("value", "mapnik")
      .attr("type", "hidden")
      .appendTo($form);

    var csrf_param = $("meta[name=csrf-param]").attr("content"),
        csrf_token = $("meta[name=csrf-token]").attr("content");

    $("<input>")
      .attr("name", csrf_param)
      .attr("value", csrf_token)
      .attr("type", "hidden")
      .appendTo($form);

    var args = {
      width: "<span id=\"mapnik_image_width\"></span>",
      height: "<span id=\"mapnik_image_height\"></span>"
    };

    $("<p>")
      .attr("class", "text-muted")
      .html(I18n.t("javascripts.share.image_dimensions", args))
      .appendTo($form);

    $("<input>")
      .attr("type", "submit")
      .attr("class", "btn btn-primary")
      .attr("value", I18n.t("javascripts.share.download"))
      .appendTo($form);

    locationFilter
      .on("change", update)
      .addTo(map);

    marker.on("dragend", movedMarker);
    map.on("move", movedMap);
    map.on("moveend layeradd layerremove", update);

    $ui
      .on("show", shown)
      .on("hide", hidden);

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
      var htmlEscapes = {
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
      var bounds = map.getBounds();

      $("#link_marker")
        .prop("checked", map.hasLayer(marker));

      $("#image_filter")
        .prop("checked", locationFilter.isEnabled());

      // Link / Embed

      $("#short_input").val(map.getShortUrl(marker));
      $("#long_input").val(map.getUrl(marker));
      $("#short_link").attr("href", map.getShortUrl(marker));
      $("#long_link").attr("href", map.getUrl(marker));

      var params = {
        bbox: bounds.toBBoxString(),
        layer: map.getMapBaseLayerId()
      };

      if (map.hasLayer(marker)) {
        var latLng = marker.getLatLng().wrap();
        params.marker = latLng.lat + "," + latLng.lng;
      }

      $("#embed_html").val(
        "<iframe width=\"425\" height=\"350\" src=\"" +
          escapeHTML(OSM.SERVER_PROTOCOL + "://" + OSM.SERVER_URL + "/export/embed.html?" + $.param(params)) +
          "\" style=\"border: 1px solid black\"></iframe><br/>" +
          "<small><a href=\"" + escapeHTML(map.getUrl(marker)) + "\">" +
          escapeHTML(I18n.t("javascripts.share.view_larger_map")) + "</a></small>");

      // Geo URI

      $("#geo_uri")
        .attr("href", map.getGeoUri(marker))
        .html(map.getGeoUri(marker));

      // Image

      if (locationFilter.isEnabled()) {
        bounds = locationFilter.getBounds();
      }

      var scale = $("#mapnik_scale").val(),
          size = L.bounds(L.CRS.EPSG3857.project(bounds.getSouthWest()),
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

      $("#mapnik_image_width").text(Math.round(size.x / scale / 0.00028));
      $("#mapnik_image_height").text(Math.round(size.y / scale / 0.00028));

      if (map.getMapBaseLayerId() === "mapnik") {
        $("#export-image").show();
        $("#export-warning").hide();
      } else {
        $("#export-image").hide();
        $("#export-warning").show();
      }
    }

    function select() {
      $(this).select();
    }

    function getScale() {
      var bounds = map.getBounds(),
          centerLat = bounds.getCenter().lat,
          halfWorldMeters = 6378137 * Math.PI * Math.cos(centerLat * Math.PI / 180),
          meters = halfWorldMeters * (bounds.getEast() - bounds.getWest()) / 180,
          pixelsPerMeter = map.getSize().x / meters,
          metersPerPixel = 1 / (92 * 39.3701);
      return Math.round(1 / (pixelsPerMeter * metersPerPixel));
    }

    function roundScale(scale) {
      var precision = 5 * Math.pow(10, Math.floor(Math.LOG10E * Math.log(scale)) - 2);
      return precision * Math.ceil(scale / precision);
    }
  };

  return control;
};
