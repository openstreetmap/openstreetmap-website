OSM.Share = function (map) {
  var page = {},
      shareButton = $(".control-share .control-button"),
      marker = L.marker([0, 0], { draggable: true }),
      locationFilter = new L.LocationFilter({
        enableButton: false,
        adjustButton: false
      });

  shareButton.on("click", function (e) {
    e.preventDefault();
    e.stopPropagation();

    OSM.router.route("/share");
  });

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
    var canEmbed = map.getMapBaseLayerId() !== "tracestracktopo";
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

    $("#embed_link")
      .toggleClass("btn-primary", canEmbed)
      .toggleClass("btn-secondary", !canEmbed)
      .tooltip(canEmbed ? "disable" : "enable");
    if (!canEmbed && $("#embed_link").hasClass("active")) {
      $("#long_link").click();
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

  page.pushstate = page.popstate = function (path) {
    OSM.loadSidebarContent(path, page.load);
  };

  page.load = function () {
    shareButton.addClass("active");

    // Link / Embed

    var $linkSectionForm = $("#share_contents .share-link form");

    $("#link_marker").bind("change", toggleMarker);

    $linkSectionForm.find(".btn-group")
      .on("click", "a", function (e) {
        e.preventDefault();
        if (!$(this).hasClass("btn-primary")) return;
        var id = "#" + $(this).attr("for");
        $(this).siblings("a")
          .removeClass("active");
        $(this).addClass("active");
        $linkSectionForm.find(".share-tab")
          .hide();
        $linkSectionForm.find(".share-tab:has(" + id + ")")
          .show()
          .find("input, textarea")
          .select();
      });

    $linkSectionForm.find(".share-tab").slice(1).hide();

    $("#long_input, #short_input, #embed_html")
      .on("click", select);

    // Image

    $("#mapnik_scale").on("change", update);

    $("#image_filter").bind("change", toggleFilter);

    locationFilter
      .on("change", update)
      .addTo(map);

    marker.on("dragend", movedMarker);
    map.on("move", movedMap);
    map.on("moveend layeradd layerremove", update);

    $("#mapnik_scale").val(getScale());
    update();
  };

  page.unload = function () {
    map.off("moveend layeradd layerremove", update);
    map.off("moveend", updateOnce);
    map.off("move", movedMap);
    marker.off("dragend", movedMarker);

    map.removeLayer(marker);
    map.options.scrollWheelZoom = map.options.doubleClickZoom = true;
    locationFilter
      .off("change", update)
      .disable();

    shareButton.removeClass("active");
  };

  return page;
};
