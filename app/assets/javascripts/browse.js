$(document).ready(function () {
  function remoteEditHandler(bbox, select) {
    var left = bbox.getWestLng() - 0.0001;
    var top = bbox.getNorthLat() + 0.0001;
    var right = bbox.getEastLng() + 0.0001;
    var bottom = bbox.getSouthLat() - 0.0001;
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
    layerControl: false,
    panZoomControl: false,
    attributionControl: false
  });

  var params = $("#small_map").data();
  if (params.type == "changeset") {
    var bbox = L.latLngBounds([params.minlat, params.minlon],
                              [params.maxlat, params.maxlon]);

    map.fitBounds(bbox);
    addBoxToMap(bbox);

    $("#loading").hide();
    $("#browse_map .geolink").show();

    $("a[data-editor=remote]").click(function () {
      return remoteEditHandler(bbox);
    });

    var centre = bbox.getCenter();
    updatelinks(centre.lng, centre.lat, 16, null, params.minlon, params.minlat, params.maxlon, params.maxlat);
  } else if (params.type == "note") {
    var object = {type: params.type, id: params.id};

    map.setView([params.lat, params.lon], 16);

    L.marker([params.lat, params.lon], { icon: getUserIcon() }).addTo(map);

    var bbox = map.getBounds();

    $("#loading").hide();
    $("#browse_map .geolink").show();

    $("a[data-editor=remote]").click(function () {
      return remoteEditHandler(bbox);
    });

    updatelinks(params.lon, params.lat, 16, null, 
                bbox.getWestLng(), bbox.getSouthLat(),
                bbox.getEastLng(), bbox.getNorthLat(),
                object);
  } else {
    $("#object_larger_map").hide();
    $("#object_edit").hide();

    var object = {type: params.type, id: params.id};

    if (!params.visible) {
      object.version = params.version - 1;
    }

    addObjectToMap(object, true, function(extent) {
      $("#loading").hide();
      $("#browse_map .geolink").show();

      if (extent) {
        $("a.bbox[data-editor=remote]").click(function () {
          return remoteEditHandler(extent);
        });

        $("a.object[data-editor=remote]").click(function () {
          return remoteEditHandler(extent, params.type + params.id);
        });

        $("#object_larger_map").show();
        $("#object_edit").show();

        var centre = extent.getCenter();
        updatelinks(centre.lng,
                    centre.lat,
                    16, null,
                    extent.getWestLng(),
                    extent.getSouthLat(),
                    extent.getEastLng(),
                    extent.getNorthLat(),
                    object);
      } else {
        $("#small_map").hide();
      }
    });
  }

  createMenu("area_edit", "area_edit_menu", "right");
  createMenu("object_edit", "object_edit_menu", "right");
});
