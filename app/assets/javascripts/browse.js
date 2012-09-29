$(document).ready(function () {
  function remoteEditHandler(bbox, select) {
    var left = bbox.left - 0.0001;
    var top = bbox.top + 0.0001;
    var right = bbox.right + 0.0001;
    var bottom = bbox.bottom - 0.0001;
    var loaded = false;

    $("#linkloader").load(function () { loaded = true; });

    if (select) {
      $("#linkloader").attr("src", "http://127.0.0.1:8111/load_and_zoom?left=" + left + "&top=" + top + "&right=" + right + "&bottom=" + bottom + "&select=" + select);
    } else {
      $("#linkloader").attr("src", "http://127.0.0.1:8111/load_and_zoom?left=" + left + "&top=" + top + "&right=" + right + "&bottom=" + bottom);
    }

    setTimeout(function () {
      if (!loaded) alert(I18n.t('site.index.remote_failed'));
    }, 1000);

    return false;
  }

  var map = createMap("small_map", {
    controls: [ new OpenLayers.Control.Navigation() ]
  });

  var params = $("#small_map").data();
  if (params.type == "changeset") {
    var bbox = new OpenLayers.Bounds(params.minlon, params.minlat, params.maxlon, params.maxlat);
    var centre = bbox.getCenterLonLat();

    map.zoomToExtent(proj(bbox));
    addBoxToMap(bbox);

    $("#loading").hide();
    $("#browse_map .geolink").show();

    $("a[data-editor=remote]").click(function () {
      return remoteEditHandler(bbox);
    });

    updatelinks(centre.lon, centre.lat, 16, null, params.minlon, params.minlat, params.maxlon, params.maxlat);
  } else {
    var url = "/api/" + OSM.API_VERSION + "/" + params.type + "/" + params.id;

    if (params.type != "node") {
      url += "/full";
    } else if (!params.visible) {
      var previous_version = params.version - 1;
      url += "/" + previous_version;
    }

    $("#object_larger_map").hide();
    $("#object_edit").hide();

    addObjectToMap(url, true, function(extent) {
      $("#loading").hide();
      $("#browse_map .geolink").show();

      if (extent) {
        extent.transform(map.getProjectionObject(), map.displayProjection);

        var centre = extent.getCenterLonLat();

        $("a.bbox[data-editor=remote]").click(function () {
          return remoteEditHandler(extent);
        });

        $("a.object[data-editor=remote]").click(function () {
          return remoteEditHandler(extent, params.type + params.id);
        });

        $("#object_larger_map").show();
        $("#object_edit").show();

        updatelinks(centre.lon, centre.lat, 16, null, extent.left, extent.bottom, extent.right, extent.top, params.type, params.id);
      } else {
        $("#small_map").hide();
      }
    });
  }

  createMenu("area_edit", "area_edit_menu", "right");
  createMenu("object_edit", "object_edit_menu", "right");
});
