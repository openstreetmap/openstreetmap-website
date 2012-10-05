//= require index/browse
//= require index/export
//= require index/key

$(document).ready(function () {
  var marker;
  var params = OSM.mapParams();
  var map = createMap("map");

  map.events.register("moveend", map, updateLocation);
  map.events.register("changelayer", map, updateLocation);

  if (!params.object_zoom) {
    if (params.bbox) {
      var bbox = new OpenLayers.Bounds(params.minlon, params.minlat, params.maxlon, params.maxlat);

      map.zoomToExtent(proj(bbox));

      if (params.box) {
        addBoxToMap(bbox);
      }
    } else {
      setMapCenter(new OpenLayers.LonLat(params.lon, params.lat), params.zoom);
    }
  }

  if (params.layers) {
    setMapLayers(params.layers);
  }

  if (params.marker) {
    marker = addMarkerToMap(new OpenLayers.LonLat(params.mlon, params.mlat));
  }

  if (params.object) {
    addObjectToMap(params.object, params.object_zoom);
  }

  handleResize();

  $("#show_data").click(function (e) {
    $.ajax({ url: $(this).attr('href'), success: function (sidebarHtml) {
      startBrowse(sidebarHtml);
    }});
    e.preventDefault();
  });

  $("body").on("click", "a.set_position", function () {
    var data = $(this).data();
    var centre = new OpenLayers.LonLat(data.lon, data.lat);

    if (data.minLon && data.minLat && data.maxLon && data.maxLat) {
      var bbox = new OpenLayers.Bounds(data.minLon, data.minLat, data.maxLon, data.maxLat);

      map.zoomToExtent(proj(bbox));
    } else {
      setMapCenter(centre, data.zoom);
    }

    if (marker) {
      removeMarkerFromMap(marker);
    }

    marker = addMarkerToMap(centre, getArrowIcon());

    return false;
  });

  function updateLocation() {
    var lonlat = unproj(map.getCenter());
    var zoom = map.getZoom();
    var layers = getMapLayers();
    var extents = unproj(map.getExtent());
    var expiry = new Date();

    updatelinks(lonlat.lon, lonlat.lat, zoom, layers, extents.left, extents.bottom, extents.right, extents.top, params.object);

    expiry.setYear(expiry.getFullYear() + 10);
    $.cookie("_osm_location", [lonlat.lon, lonlat.lat, zoom, layers].join("|"), {expires: expiry});
  }

  function remoteEditHandler(event) {
    var extent = unproj(map.getExtent());
    var loaded = false;

    $("#linkloader").load(function () { loaded = true; });
    $("#linkloader").attr("src", "http://127.0.0.1:8111/load_and_zoom?left=" + extent.left + "&top=" + extent.top + "&right=" + extent.right + "&bottom=" + extent.bottom);

    setTimeout(function () {
      if (!loaded) alert(I18n.t('site.index.remote_failed'));
    }, 1000);

    return false;
  }

  $("a[data-editor=remote]").click(remoteEditHandler);

  if (OSM.preferred_editor == "remote" && $('body').hasClass("site-edit")) {
    remoteEditHandler();
  }

  $(window).resize(function() {
    var centre = map.getCenter();
    var zoom = map.getZoom();

    handleResize();

    map.setCenter(centre, zoom);
  });

  $("#search_form").submit(function () {
    var extent = unproj(map.getExtent());

    $("#sidebar_title").html(I18n.t('site.sidebar.search_results'));
    $("#sidebar_content").load($(this).attr("action"), {
      query: $("#query").val(),
      minlon: extent.left,
      minlat: extent.bottom,
      maxlon: extent.right,
      maxlat: extent.top
    }, openSidebar);

    return false;
  });

  if ($("#query").val()) {
    $("#search_form").submit();
  }
});
