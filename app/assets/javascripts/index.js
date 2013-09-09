//= require_self
//= require leaflet.sidebar
//= require leaflet.locate
//= require leaflet.layers
//= require leaflet.key
//= require leaflet.note
//= require leaflet.share
//= require index/search
//= require index/browse
//= require index/export
//= require index/notes

$(document).ready(function () {
  var params = OSM.mapParams();

  var map = L.map("map", {
    zoomControl: false,
    layerControl: false
  });

  map.attributionControl.setPrefix('');

  map.hash = L.hash(map);

  var copyright = I18n.t('javascripts.map.copyright', {copyright_url: '/copyright'});

  var layers = [
    new L.OSM.Mapnik({
      attribution: copyright,
      code: "M",
      keyid: "mapnik",
      name: I18n.t("javascripts.map.base.standard")
    }),
    new L.OSM.CycleMap({
      attribution: copyright + ". Tiles courtesy of <a href='http://www.opencyclemap.org/' target='_blank'>Andy Allan</a>",
      code: "C",
      keyid: "cyclemap",
      name: I18n.t("javascripts.map.base.cycle_map")
    }),
    new L.OSM.TransportMap({
      attribution: copyright + ". Tiles courtesy of <a href='http://www.opencyclemap.org/' target='_blank'>Andy Allan</a>",
      code: "T",
      keyid: "transportmap",
      name: I18n.t("javascripts.map.base.transport_map")
    }),
    new L.OSM.MapQuestOpen({
      attribution: copyright + ". Tiles courtesy of <a href='http://www.mapquest.com/' target='_blank'>MapQuest</a> <img src='http://developer.mapquest.com/content/osm/mq_logo.png'>",
      code: "Q",
      keyid: "mapquest",
      name: I18n.t("javascripts.map.base.mapquest")
    })
  ];

  function updateLayers(params) {
    var layerParam = params.layers || "M";
    var layersAdded = "";

    for (var i = layers.length - 1; i >= 0; i--) {
      if (layerParam.indexOf(layers[i].options.code) >= 0) {
        map.addLayer(layers[i]);
        layersAdded = layersAdded + layers[i].options.code;
      } else {
        map.removeLayer(layers[i]);
      }
    }

    if (layersAdded == "") {
      map.addLayer(layers[0]);
    }
  }

  updateLayers(params);

  $(window).on("hashchange", function () {
    updateLayers(OSM.mapParams());
  });

  map.noteLayer = new L.LayerGroup();
  map.noteLayer.options = {code: 'N'};

  map.dataLayer = new L.OSM.DataLayer(null);
  map.dataLayer.options.code = 'D';

  $("#sidebar").on("opened closed", function () {
    map.invalidateSize();
  });

  var position = $('html').attr('dir') === 'rtl' ? 'topleft' : 'topright';

  L.OSM.zoom({position: position})
    .addTo(map);

  L.control.locate({
    position: position,
    strings: {
      title: I18n.t('javascripts.map.locate.title'),
      popup: I18n.t('javascripts.map.locate.popup')
    }
  }).addTo(map);

  var sidebar = L.OSM.sidebar('#map-ui')
    .addTo(map);

  L.OSM.layers({
    position: position,
    layers: layers,
    sidebar: sidebar
  }).addTo(map);

  L.OSM.key({
    position: position,
    sidebar: sidebar
  }).addTo(map);

  L.OSM.share({
    position: position,
    sidebar: sidebar,
    short: true
  }).addTo(map);

  L.OSM.note({
    position: position,
    sidebar: sidebar
  }).addTo(map);

  L.control.scale()
    .addTo(map);

  $('.leaflet-control .control-button').tooltip({placement: 'left', container: 'body'});

  map.on('moveend layeradd layerremove', updateLocation);

  if (OSM.PIWIK) {
    map.on('layeradd', function (e) {
      if (e.layer.options) {
        var goal = OSM.PIWIK.goals[e.layer.options.keyid];

        if (goal) {
          $('body').trigger('piwikgoal', goal);
        }
      }
    });
  }

  var marker = L.marker([0, 0], {icon: getUserIcon()});

  if (!params.object_zoom) {
    if (params.bounds) {
      map.fitBounds(params.bounds);
    } else {
      map.setView([params.lat, params.lon], params.zoom);
    }
  }

  if (params.box) {
    L.rectangle(params.box, {
      weight: 2,
      color: '#e90',
      fillOpacity: 0
    }).addTo(map);
  }

  if (params.marker) {
    marker.setLatLng([params.mlat, params.mlon]).addTo(map);
  }

  if (params.object) {
    map.addObject(params.object, { zoom: params.object_zoom });
  }

  $("#homeanchor").on("click", function(e) {
    e.preventDefault();

    var data = $(this).data(),
      center = L.latLng(data.lat, data.lon);

    map.setView(center, data.zoom);
    marker.setLatLng(center).addTo(map);
  });

  $("a[data-editor=remote]").click(function(e) {
      remoteEditHandler(map.getBounds());
      e.preventDefault();
  });

  if (OSM.preferred_editor == "remote" && $('body').hasClass("site-edit")) {
    remoteEditHandler(map.getBounds());
  }

  if (OSM.params().edit_help) {
    $('#editanchor')
      .removeAttr('title')
      .tooltip({
        placement: 'bottom',
        title: I18n.t('javascripts.edit_help')
      })
      .tooltip('show');

    $('body').one('click', function() {
      $('#editanchor').tooltip('hide');
    });
  }

  initializeSearch(map);
  initializeExport(map);
  initializeBrowse(map, params);
  initializeNotes(map, params);
});

function updateLocation() {
  updatelinks(this.getCenter().wrap(),
      this.getZoom(),
      this.getLayersCode(),
      this.getBounds().wrap());

  var expiry = new Date();
  expiry.setYear(expiry.getFullYear() + 10);
  $.cookie("_osm_location", cookieContent(this), { expires: expiry });

  // Trigger hash update on layer changes.
  this.hash.onMapMove();
}
