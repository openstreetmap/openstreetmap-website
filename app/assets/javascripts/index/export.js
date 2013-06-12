function initializeExport(map) {
  $("#exportanchor").click(function (e) {
    $.ajax({ url: $(this).data('url'), success: function (sidebarHtml) {
      startExport(sidebarHtml);
    }});
    e.preventDefault();
  });

  if (window.location.pathname == "/export") {
    $("#exportanchor").click();
  }

  function startExport(sidebarHtml) {
    var marker;

    var locationFilter = new L.LocationFilter({
      enableButton: false,
      adjustButton: false
    }).addTo(map);

    locationFilter.on("change", filterChanged);

    map.on("moveend", mapMoved);
    map.on("baselayerchange", htmlUrlChanged);

    $("#sidebar_title").html(I18n.t('export.start_rjs.export'));
    $("#sidebar_content").html(sidebarHtml);

    $("#maxlat,#minlon,#maxlon,#minlat").change(boundsChanged);

    $("#drag_box").click(enableFilter);

    $("#add_marker").click(startMarker);

    $("#format_osm,#format_mapnik,#format_html").click(formatChanged);

    $("#mapnik_scale").change(mapnikSizeChanged);

    openSidebar();

    if (getMapBaseLayerId(map) == "mapnik") {
      $("#format_mapnik").prop("checked", true);
    }

    setBounds(map.getBounds());
    formatChanged();

    $("body").removeClass("site-index").addClass("site-export");

    $("#sidebar").one("closed", function () {
      $("body").removeClass("site-export").addClass("site-index");

      map.removeLayer(locationFilter);
      clearMarker();

      map.off("moveend", mapMoved);
      map.off("baselayerchange", htmlUrlChanged);
      locationFilter.off("change", filterChanged);
    });

    function getBounds() {
      return L.latLngBounds(L.latLng($("#minlat").val(), $("#minlon").val()),
                            L.latLng($("#maxlat").val(), $("#maxlon").val()));
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

    function getMercatorBounds() {
      var bounds = getBounds();
      return L.bounds(L.CRS.EPSG3857.project(bounds.getSouthWest()),
                      L.CRS.EPSG3857.project(bounds.getNorthEast()));
    }

    function boundsChanged() {
      var bounds = getBounds();

      map.fitBounds(bounds);
      locationFilter.setBounds(bounds);

      enableFilter();
      validateControls();
      mapnikSizeChanged();
    }

    function enableFilter() {
      if (!locationFilter.getBounds().isValid()) {
        locationFilter.setBounds(map.getBounds().pad(-0.2));
      }

      $("#drag_box").hide();
      locationFilter.enable();
    }

    function filterChanged() {
      setBounds(locationFilter.getBounds());
      validateControls();
    }

    function startMarker() {
      $("#add_marker").html(I18n.t('export.start_rjs.click_add_marker'));

      map.on("click", endMarker);

      return false;
    }

    function endMarker(event) {
      map.off("click", endMarker);

      $("#add_marker").html(I18n.t('export.start_rjs.change_marker'));
      $("#marker_inputs").show();

      var latlng = event.latlng;

      if (marker) {
        map.removeLayer(marker);
      }

      marker = L.marker(latlng).addTo(map);

      $("#marker_lon").val(latlng.lng.toFixed(5));
      $("#marker_lat").val(latlng.lat.toFixed(5));

      htmlUrlChanged();
    }

    function clearMarker() {
      $("#marker_lon,#marker_lat").val("");
      $("#marker_inputs").hide();
      $("#add_marker").html(I18n.t('export.start_rjs.add_marker'));

      if (marker) {
        map.removeLayer(marker);
      }
    }

    function mapMoved() {
      if (!locationFilter.isEnabled()) {
        setBounds(map.getBounds());
        validateControls();
      }
    }

    function setBounds(bounds) {
      var toPrecision = zoomPrecision(map.getZoom());

      $("#minlon").val(toPrecision(bounds.getWest()));
      $("#minlat").val(toPrecision(bounds.getSouth()));
      $("#maxlon").val(toPrecision(bounds.getEast()));
      $("#maxlat").val(toPrecision(bounds.getNorth()));

      mapnikSizeChanged();
      htmlUrlChanged();
    }

    function validateControls() {
      var bounds = getBounds();

      var tooLarge = bounds.getSize() > OSM.MAX_REQUEST_AREA;
      if (tooLarge) {
        $("#export_osm_too_large").show();
      } else {
        $("#export_osm_too_large").hide();
      }

      var max_scale = maxMapnikScale();
      var disabled = true;

      if ($("#format_osm").prop("checked")) {
        disabled = tooLarge;
      } else if ($("#format_mapnik").prop("checked")) {
        disabled = $("#mapnik_scale").val() < max_scale;
      }

      $("#export_commit").prop("disabled", disabled);
      $("#mapnik_max_scale").html(roundScale(max_scale));
    }

    function htmlUrlChanged() {
      var bounds = getBounds();
      var layerName = getMapBaseLayerId(map);

      var url = "http://" + OSM.SERVER_URL + "/export/embed.html?bbox=" + bounds.toBBoxString() + "&amp;layer=" + layerName;
      var markerUrl = "";

      if ($("#marker_lat").val() && $("#marker_lon").val()) {
        markerUrl = "&amp;mlat=" + $("#marker_lat").val() + "&amp;mlon=" + $("#marker_lon").val();
        url += "&amp;marker=" + $("#marker_lat").val() + "," + $("#marker_lon").val();
      }

      var html = '<iframe width="425" height="350" frameborder="0" scrolling="no" marginheight="0" marginwidth="0" src="'+url+'" style="border: 1px solid black"></iframe>';

      // Create "larger map" link
      var center = bounds.getCenter();

      var zoom = map.getBoundsZoom(bounds);

      var layers = getMapLayers(map);

      var text = I18n.t('export.start_rjs.view_larger_map');
      var escaped = [];

      for (var i = 0; i < text.length; ++i) {
        var c = text.charCodeAt(i);
        escaped.push(c < 127 ? text.charAt(i) : "&#" + c + ";");
      }

      html += '<br /><small><a href="http://' + OSM.SERVER_URL + '/?lat='+center.lat+'&amp;lon='+center.lng+'&amp;zoom='+zoom+'&amp;layers='+layers+markerUrl+'">'+escaped.join("")+'</a></small>';

      $("#export_html_text").val(html);

      if ($("#format_html").prop("checked")) {
        $("#export_html_text").prop("selected", true);
      }
    }

    function formatChanged() {
      $("#export_commit").show();

      if ($("#format_osm").prop("checked")) {
        $("#export_osm").show();
      } else {
        $("#export_osm").hide();
      }

      if ($("#format_mapnik").prop("checked")) {
        $("#mapnik_scale").val(getScale());
        $("#export_mapnik").show();

        mapnikSizeChanged();
      } else {
        $("#export_mapnik").hide();
      }

      if ($("#format_html").prop("checked")) {
        $("#export_html").show();
        $("#export_commit").hide();
        $("#export_html_text").prop("selected", true);
      } else {
        $("#export_html").hide();

        clearMarker();
      }

      validateControls();
    }

    function maxMapnikScale() {
      var size = getMercatorBounds().getSize();

      return Math.floor(Math.sqrt(size.x * size.y / 0.3136));
    }

    function mapnikImageSize(scale) {
      var size = getMercatorBounds().getSize();

      return {w: Math.round(size.x / scale / 0.00028),
              h: Math.round(size.y / scale / 0.00028)};
    }

    function roundScale(scale) {
      var precision = 5 * Math.pow(10, Math.floor(Math.LOG10E * Math.log(scale)) - 2);

      return precision * Math.ceil(scale / precision);
    }

    function mapnikSizeChanged() {
      var size = mapnikImageSize($("#mapnik_scale").val());

      $("#mapnik_image_width").html(size.w);
      $("#mapnik_image_height").html(size.h);

      validateControls();
    }
  }
}
