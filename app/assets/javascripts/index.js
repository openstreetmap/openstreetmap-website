//= require_self
//= require leaflet.layers
//= require leaflet.share
//= require leaflet.note
//= require leaflet.locate
//= require leaflet.customzoom
//= require index/browse
//= require index/export
//= require index/key
//= require index/notes

function allLayers() {
  return [{
    layer: new L.OSM.Mapnik({
      attribution: '',
      code: "M"
    }),
    keyid: "mapnik",
    name: I18n.t("javascripts.map.base.standard")
  }, {
    layer: new L.OSM.CycleMap({
      attribution: "Tiles courtesy of <a href='http://www.opencyclemap.org/' target='_blank'>Andy Allan</a>",
      code: "C"
    }),
    keyid: "cyclemap",
    name: I18n.t("javascripts.map.base.cycle_map")
  }, {
    layer: new L.OSM.TransportMap({
      attribution: "Tiles courtesy of <a href='http://www.opencyclemap.org/' target='_blank'>Andy Allan</a>",
      code: "T"
    }),
    keyid: "transportmap",
    name: I18n.t("javascripts.map.base.transport_map")
  }, {
    layer: new L.OSM.MapQuestOpen({
      attribution: "Tiles courtesy of <a href='http://www.mapquest.com/' target='_blank'>MapQuest</a> <img src='http://developer.mapquest.com/content/osm/mq_logo.png'>",
      code: "Q"
    }),
    keyid: "mapquest",
    name: I18n.t("javascripts.map.base.mapquest")
  }];
}

$(document).ready(function () {
  var params = OSM.mapParams();

  var map = L.map("map", {
    zoomControl: false,
    layerControl: false
  });

  map.attributionControl.setPrefix('');

  var layers = allLayers();

  layers[0].layer.addTo(map);

  $("#map").on("resized", function () {
    map.invalidateSize();
  });

  L.control.customZoom({position: 'topright'})
    .addTo(map);

  var uiPane = $('#map-ui')[0];

  L.OSM.layers({
    position: 'topright',
    layers: layers,
    uiPane: uiPane
  }).addTo(map);

  L.control.share({
    getUrl: getShortUrl,
    uiPane: uiPane
  }).addTo(map);

  L.control.note({ position: 'topright' }).addTo(map);
  L.control.locate({ position: 'topright' }).addTo(map);
  L.control.scale().addTo(map);

  map.on('moveend layeradd layerremove', updateLocation);

  map.markerLayer = L.layerGroup().addTo(map);

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
    var foundLayer = false;
    for (var i = 0; i < layers.length; i++) {
      if (params.layers.indexOf(layers[i].layer.options.code) >= 0) {
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

  if (params.marker) {
    L.marker([params.mlat, params.mlon], {icon: getUserIcon()}).addTo(map.markerLayer);
  }

  if (params.object) {
    addObjectToMap(params.object, map, { zoom: params.object_zoom });
  }

  handleResize();

  $("body").on("click", "a.set_position", setPositionLink(map));

  $("a[data-editor=remote]").click(function(e) {
      remoteEditHandler(map.getBounds());
      e.preventDefault();
  });

  if (OSM.preferred_editor == "remote" && $('body').hasClass("site-edit")) {
    remoteEditHandler(map.getBounds());
  }

  $(window).resize(handleResize);

  $("#search_form").submit(submitSearch(map));


  if ($("#query").val()) {
    $("#search_form").submit();
  }

  // Focus the search field for browsers that don't support
  // the HTML5 'autofocus' attribute
  if (!("autofocus" in document.createElement("input"))) {
    $("#query").focus();
  }
});

// non-scoped utilities
function getMapBaseLayer() {
  for (var i = 0; i < layers.length; i++) {
    if (map.hasLayer(layers[i].layer)) {
      return layers[i];
    }
  }
}

function getMapLayers(map) {
  var layerConfig = '';
  for (var i in map._layers) { // TODO: map.eachLayer
    var layer = map._layers[i];
    if (layer.options && layer.options.code) {
      layerConfig += layer.options.code;
    }
  }
  return layerConfig;
}

// generate a cookie-safe string of map state
function cookieContent(map) {
  var center = map.getCenter().wrap();
  return [center.lng, center.lat, map.getZoom(), getMapLayers(map)].join('|');
}

function updateLocation() {
  updatelinks(this.getCenter().wrap(),
      this.getZoom(),
      getMapLayers(this),
      this.getBounds().wrap(), {});

  var expiry = new Date();
  expiry.setYear(expiry.getFullYear() + 10);
  $.cookie("_osm_location", cookieContent(this), { expires: expiry });
}

function setPositionLink(map) {
  return function(e) {
      var data = $(this).data(),
          center = L.latLng(data.lat, data.lon);

      if (data.minLon && data.minLat && data.maxLon && data.maxLat) {
        map.fitBounds([[data.minLat, data.minLon],
                       [data.maxLat, data.maxLon]]);
      } else {
        map.setView(center, data.zoom);
      }

      if (data.type && data.id) {
        addObjectToMap(data, map, { zoom: true, style: { opacity: 0.2, fill: false } });
      }

      map.markerLayer.clearLayers();
      L.marker(center, {icon: getUserIcon()}).addTo(map.markerLayer);

      return e.preventDefault();
  };
}

function submitSearch(map) {
  return function(e) {
    var bounds = map.getBounds();

    $("#sidebar_title").html(I18n.t('site.sidebar.search_results'));
    $("#sidebar_content").load($(this).attr("action"), {
      query: $("#query").val(),
      minlon: bounds.getWestLng(),
      minlat: bounds.getSouthLat(),
      maxlon: bounds.getEastLng(),
      maxlat: bounds.getNorthLat()
    }, openSidebar);

    return e.preventDefault();
  };
}
