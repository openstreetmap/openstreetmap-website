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
//= require index/history
//= require index/note
//= require router

$(document).ready(function () {
  var params = OSM.mapParams();

  var map = L.map("map", {
    zoomControl: false,
    layerControl: false
  });

  map.attributionControl.setPrefix('');

  map.hash = L.hash(map);

  $(window).on('popstate', function(e) {
    // popstate is triggered when the hash changes as well as on actual navigation
    // events. We want to update the hash on the latter and not the former.
    if (e.originalEvent.state) {
      map.hash.update();
    }
  });

  var copyright = I18n.t('javascripts.map.copyright', {copyright_url: '/copyright'});
  var donate = I18n.t('javascripts.map.donate_link_text', {donate_url: 'http://donate.openstreetmap.org'});

  var layers = [
    new L.OSM.Mapnik({
      attribution: copyright + " &hearts; " + donate,
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
    }),
    new L.OSM.HOT({
      attribution: copyright + ". Tiles courtesy of <a href='http://hot.openstreetmap.org/' target='_blank'>Humanitarian OpenStreetMap Team</a>",
      code: "H",
      keyid: "hot",
      name: I18n.t("javascripts.map.base.hot")
    })
  ];

  function updateLayers(params) {
    var layerParam = params.layers || "M";
    var layersAdded = "";

    for (var i = layers.length - 1; i >= 0; i--) {
      if (layerParam.indexOf(layers[i].options.code) >= 0) {
        map.addLayer(layers[i]);
        layersAdded = layersAdded + layers[i].options.code;
      } else if (i == 0 && layersAdded == "") {
        map.addLayer(layers[i]);
      } else {
        map.removeLayer(layers[i]);
      }
    }
  }

  updateLayers(params);

  $(window).on("hashchange", function () {
    updateLayers(OSM.mapParams());
  });

  map.on("baselayerchange", function (e) {
    if (map.getZoom() > e.layer.options.maxZoom) {
      map.setView(map.getCenter(), e.layer.options.maxZoom, { reset: true });
    }
  });

  map.noteLayer = new L.LayerGroup();
  map.noteLayer.options = {code: 'N'};

  map.dataLayer = new L.OSM.DataLayer(null);
  map.dataLayer.options.code = 'D';

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

  if (OSM.STATUS != 'api_offline' && OSM.STATUS != 'database_offline') {
    initializeNotes(map);
    if (params.layers.indexOf(map.noteLayer.options.code) >= 0) {
      map.addLayer(map.noteLayer);
    }

    initializeBrowse(map);
    if (params.layers.indexOf(map.dataLayer.options.code) >= 0) {
      map.addLayer(map.dataLayer);
    }
  }

  $('.leaflet-control .control-button').tooltip({placement: 'left', container: 'body'});

  map.on('moveend layeradd layerremove', function() {
    updatelinks(
      map.getCenter().wrap(),
      map.getZoom(),
      map.getLayersCode(),
      map._object);

    var expiry = new Date();
    expiry.setYear(expiry.getFullYear() + 10);
    $.cookie("_osm_location", cookieContent(map), { expires: expiry });

    // Trigger hash update on layer changes.
    map.hash.onMapMove();
  });

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

  if (params.bounds) {
    map.fitBounds(params.bounds);
  } else {
    map.setView([params.lat, params.lon], params.zoom);
  }

  var marker = L.marker([0, 0], {icon: getUserIcon()});

  if (params.marker) {
    marker.setLatLng([params.mlat, params.mlon]).addTo(map);
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

  OSM.Index = function(map) {
    var page = {};

    page.pushstate = page.popstate = function(path) {
      $("#content").addClass("overlay-sidebar");
      map.invalidateSize();
      $('#sidebar_content').load(path + "?xhr=1", function(a, b, xhr) {
        if (xhr.getResponseHeader('X-Page-Title')) {
          document.title = xhr.getResponseHeader('X-Page-Title');
        }
      });
    };

    page.unload = function() {
      $("#content").removeClass("overlay-sidebar");
      map.invalidateSize();
    };

    return page;
  };

  OSM.Browse = function(map) {
    var page = {};

    page.pushstate = page.popstate = function(path, type, id) {
      $('#sidebar_content').load(path + "?xhr=1", function(a, b, xhr) {
        if (xhr.getResponseHeader('X-Page-Title')) {
          document.title = xhr.getResponseHeader('X-Page-Title');
        }
        page.load(path, type, id);
      });
    };

    page.load = function(path, type, id) {
      if (OSM.STATUS === 'api_offline' || OSM.STATUS === 'database_offline') return;

      if (type === 'note') {
        map.noteLayer.showNote(parseInt(id));
      } else {
        map.addObject({type: type, id: parseInt(id)}, {zoom: true});
      }
    };

    page.unload = function() {
      map.removeObject();
    };

    return page;
  };

  var history = OSM.History(map),
    note = OSM.Note(map);

  OSM.route = OSM.Router({
    "/":                           OSM.Index(map),
    "/search":                     OSM.Search(map),
    "/export":                     OSM.Export(map),
    "/history":                    history,
    "/user/:display_name/edits":   history,
    "/browse/friends":             history,
    "/browse/nearby":              history,
    "/browse/note/:id":            note,
    "/browse/:type/:id(/history)": OSM.Browse(map)
  });

  $(document).on("click", "a", function(e) {
    if (e.isDefaultPrevented() || e.isPropagationStopped()) return;
    if (this.host === window.location.host && OSM.route(this.pathname + this.search + this.hash)) e.preventDefault();
  });

  $(".search_form").on("submit", function(e) {
    e.preventDefault();
    $("header").addClass("closed");
    OSM.route("/search?query=" + encodeURIComponent($(this).find("input[name=query]").val()) + OSM.formatHash(map));
  });

  $(".describe_location").on("click", function(e) {
    e.preventDefault();
    var precision = zoomPrecision(map.getZoom());
    OSM.route("/search?query=" + encodeURIComponent(
      map.getCenter().lat.toFixed(precision) + "," +
      map.getCenter().lng.toFixed(precision)));
  });
});
