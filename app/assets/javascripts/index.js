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

var map, layers; // TODO: remove globals

$(document).ready(function () {
  var marker;
  var params = OSM.mapParams();

  var map = L.map("map", {
    zoomControl: false,
    layerControl: false
  });

  map.attributionControl.setPrefix('');

  layers = [{
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

  L.control.note({
    position: 'topright'
  }).addTo(map);

  L.control.locate({
    position: 'topright'
  }).addTo(map);

  L.control.scale().addTo(map);

  map.on('moveend layeradd layerremove', updateLocation);

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

  // generate a cookie-safe string of map state
  function cookieContent(map) {
    var center = map.getCenter().wrap();
    return [center.lng, center.lat, map.getZoom(), getMapLayers(map)].join('|');
  }

  function updateLocation() {
    updatelinks(map.getCenter().wrap(),
        map.getZoom(),
        getMapLayers(this),
        map.getBounds().wrap(),
        params.object);

    var expiry = new Date();
    expiry.setYear(expiry.getFullYear() + 10);
    $.cookie("_osm_location", cookieContent(map), { expires: expiry });
  }

  function remoteEditHandler() {
    var extent = map.getBounds();
    var loaded = false;

    $("#linkloader").load(function () { loaded = true; });
    $("#linkloader").attr("src", "http://127.0.0.1:8111/load_and_zoom?" +
         querystring.stringify({
            left: extent.getWest(),
            bottom: extent.getSouth(),
            right: extent.getEast(),
            top: extent.getNorth()
         }));

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
