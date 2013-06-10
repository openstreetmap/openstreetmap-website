$(document).ready(function () {
  function remoteEditHandler(bbox, select) {
    var left = bbox.getWest() - 0.0001;
    var top = bbox.getNorth() + 0.0001;
    var right = bbox.getEast() + 0.0001;
    var bottom = bbox.getSouth() - 0.0001;
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

  var map = L.map("small_map", {
    attributionControl: false,
    zoomControl: false
  }).addLayer(new L.OSM.Mapnik());

  L.control.zoom({position: 'topright'})
    .addTo(map);

  $("#small_map").on("resized", function () {
    map.invalidateSize();
  });

  var params = $("#small_map").data();
  var object, bbox;
  if (params.type == "changeset") {
    bbox = L.latLngBounds([params.minlat, params.minlon],
        [params.maxlat, params.maxlon]);

    map.fitBounds(bbox);

    L.rectangle(bbox, {
      weight: 2,
      color: '#e90',
      fillOpacity: 0
    }).addTo(map);

    $("#loading").hide();
    $("#browse_map .geolink").show();

    $("a[data-editor=remote]").click(function () {
      return remoteEditHandler(bbox);
    });

    updatelinks(map.getCenter(), 16, null, [[params.minlat, params.minlon],
        [params.maxlat, params.maxlon]]);
  } else if (params.type == "note") {
    object = {type: params.type, id: params.id};

    map.setView([params.lat, params.lon], 16);

    L.marker([params.lat, params.lon], { icon: getUserIcon() }).addTo(map);

    bbox = map.getBounds();

    $("#loading").hide();
    $("#browse_map .geolink").show();

    $("a[data-editor=remote]").click(function () {
      return remoteEditHandler(bbox);
    });

    updatelinks(params, 16, null,
                bbox.getWest(), bbox.getSouth(),
                bbox.getEast(), bbox.getNorth(),
                object);
  } else {
    $("#object_larger_map, #object_edit").hide();

    object = {type: params.type, id: params.id};

    if (!params.visible) {
      object.version = params.version - 1;
    }

    addObjectToMap(object, map, {
      zoom: true, 
      callback: function(extent) {
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

          updatelinks(map.getCenter(), 16, null, extent, object);
        } else {
          $("#small_map").hide();
        }
      }
    });
  }

  createMenu("area_edit", "area_edit_menu", "right");
  createMenu("object_edit", "object_edit_menu", "right");
});
