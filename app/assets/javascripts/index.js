//= require_self
//= require index/browse
//= require index/export
//= require index/key
//= require index/notes
//= require index/map_ui

var map, layers; // TODO: remove globals

$(document).ready(function () {
  var marker;
  var params = OSM.mapParams();

  map = L.map("map", {
    attributionControl: false,
    zoomControl: false,
    layerControl: false
  });

  layers = mapLayers();

  layers[0].layer.addTo(map);

  $("#map").on("resized", function () {
    map.invalidateSize();
  });

  L.control.zoom({position: 'topright'})
    .addTo(map);

  OSM.mapUI().addTo(map);

  L.control.share({
      getUrl: function(map) {
          return setArgs('http://osm.org/', {
              lon: map.getCenter().lng,
              lat: map.getCenter().lat
          });
      }
  }).addTo(map);

  L.control.note({
      position: 'topright'
  }).addTo(map);

  L.control.locate({
      position: 'topright'
  }).addTo(map);

  L.control.scale().addTo(map);

  map.on("moveend layeradd layerremove", updateLocation);

  if (!params.object_zoom) {
    if (params.bbox) {
      var bbox = L.latLngBounds([params.minlat, params.minlon],
                                [params.maxlat, params.maxlon]);

      map.fitBounds(bbox);

      if (params.box) {
        L.rectangle(bbox, {
          weight: 2,
          color: '#e90',
          fillOpacity: 0
        }).addTo(map);
      }
    } else {
      map.setView([params.lat, params.lon], params.zoom);
    }
  }

  if (params.layers) {
    setMapLayers(params.layers);
  }

  if (params.marker) {
    marker = L.marker([params.mlat, params.mlon], {icon: getUserIcon()}).addTo(map);
  }

  if (params.object) {
    addObjectToMap(params.object, map, { zoom: params.object_zoom });
  }

  handleResize();

  $("body").on("click", "a.set_position", function (e) {
    e.preventDefault();

    var data = $(this).data();
    var centre = L.latLng(data.lat, data.lon);

    if (data.minLon && data.minLat && data.maxLon && data.maxLat) {
      map.fitBounds([[data.minLat, data.minLon],
                     [data.maxLat, data.maxLon]]);
    } else {
      map.setView(centre, data.zoom);
    }

    if (data.type && data.id) {
      addObjectToMap(data, map, { zoom: true, style: { opacity: 0.2, fill: false } });
    }

    if (marker) {
      map.removeLayer(marker);
    }

    marker = L.marker(centre, {icon: getUserIcon()}).addTo(map);
  });

  function updateLocation() {
    var center = map.getCenter().wrap();
    var zoom = map.getZoom();
    var layers = getMapLayers();
    var extents = map.getBounds().wrap();

    updatelinks(center.lng,
                center.lat,
                zoom,
                layers,
                extents.getWest(),
                extents.getSouth(),
                extents.getEast(),
                extents.getNorth(),
                params.object);

    var expiry = new Date();
    expiry.setYear(expiry.getFullYear() + 10);
    $.cookie("_osm_location", [center.lng, center.lat, zoom, layers].join("|"), {expires: expiry});
  }

  function remoteEditHandler() {
    var extent = map.getBounds();
    var loaded = false;

    $("#linkloader").load(function () { loaded = true; });
    $("#linkloader").attr("src", "http://127.0.0.1:8111/load_and_zoom?left=" + extent.getWest()
                                                                   + "&bottom=" + extent.getSouth()
                                                                   + "&right=" + extent.getEast()
                                                                   + "&top=" + extent.getNorth());

    setTimeout(function () {
      if (!loaded) alert(I18n.t('site.index.remote_failed'));
    }, 1000);

    return false;
  }

  $("a[data-editor=remote]").click(remoteEditHandler);

  if (OSM.preferred_editor == "remote" && $('body').hasClass("site-edit")) {
    remoteEditHandler();
  }

  $(window).resize(handleResize);

  $("#search_form").submit(function () {
    var bounds = map.getBounds();

    $("#sidebar_title").html(I18n.t('site.sidebar.search_results'));
    $("#sidebar_content").load($(this).attr("action"), {
      query: $("#query").val(),
      minlon: bounds.getWest(),
      minlat: bounds.getSouth(),
      maxlon: bounds.getEast(),
      maxlat: bounds.getNorth()
    }, openSidebar);

    return false;
  });

  if ($("#query").val()) {
    $("#search_form").submit();
  }

  // Focus the search field for browsers that don't support
  // the HTML5 'autofocus' attribute
  if (!("autofocus" in document.createElement("input"))) {
    $("#query").focus();
  }
});

function getMapBaseLayer() {
  for (var i = 0; i < layers.length; i++) {
    if (map.hasLayer(layers[i].layer)) {
      return layers[i];
    }
  }
}

function getMapLayers() {
  var layerConfig = "";
  for (var i = 0; i < layers.length; i++) {
    if (map.hasLayer(layers[i].layer)) {
      layerConfig += layers[i].layerCode;
    }
  }
  return layerConfig;
}

function setMapLayers(layerConfig) {
  var foundLayer = false;
  for (var i = 0; i < layers.length; i++) {
    if (layerConfig.indexOf(layers[i].layerCode) >= 0) {
      map.addLayer(layers[i].layer);
      foundLayer = true;
    } else {
      map.removeLayer(layers[i].layer);
    }
  }
  if (!foundLayer) {
    map.addLayer(layers[0].layer);
  }
}
