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
//= require index/new_note
//= require router

(function() {
  var loaderTimeout;

  OSM.loadSidebarContent = function(path, callback) {
    clearTimeout(loaderTimeout);

    loaderTimeout = setTimeout(function() {
      $('#sidebar_loader').show();
    }, 200);

    // IE<10 doesn't respect Vary: X-Requested-With header, so
    // prevent caching the XHR response as a full-page URL.
    if (path.indexOf('?') >= 0) {
      path += '&xhr=1'
    } else {
      path += '?xhr=1'
    }

    $('#sidebar_content')
      .empty();

    $.ajax({
      url: path,
      dataType: "html",
      complete: function(xhr) {
        clearTimeout(loaderTimeout);
        $('#sidebar_loader').hide();
        $('#sidebar_content').html(xhr.responseText);
        if (xhr.getResponseHeader('X-Page-Title')) {
          document.title = xhr.getResponseHeader('X-Page-Title');
        }
        if (callback) {
          callback();
        }
      }
    });
  };
})();

$(document).ready(function () {
  var params = OSM.mapParams();

  var map = new L.OSM.Map("map", {
    zoomControl: false,
    layerControl: false
  });

  map.attributionControl.setPrefix('');

  map.updateLayers(params.layers);

  map.on("baselayerchange", function (e) {
    if (map.getZoom() > e.layer.options.maxZoom) {
      map.setView(map.getCenter(), e.layer.options.maxZoom, { reset: true });
    }
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
    layers: map.baseLayers,
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

    page.pushstate = function(path) {
      $("#content").addClass("overlay-sidebar");
      map.invalidateSize({pan: false})
        .panBy([-300, 0], {animate: false});
      OSM.loadSidebarContent(path);
      page.load();
    };

    page.load = function() {
      return map.getState();
    };

    page.popstate = function(path) {
      $("#content").addClass("overlay-sidebar");
      map.invalidateSize({pan: false});
      OSM.loadSidebarContent(path);
    };

    page.unload = function() {
      map.panBy([300, 0], {animate: false});
      $("#content").removeClass("overlay-sidebar");
      map.invalidateSize({pan: false});
    };

    return page;
  };

  OSM.Browse = function(map) {
    var page = {};

    page.pushstate = page.popstate = function(path, type, id) {
      OSM.loadSidebarContent(path, function() {
        page.load(path, type, id);
      });
    };

    page.load = function(path, type, id) {
      map.addObject({type: type, id: parseInt(id)});
    };

    page.unload = function() {
      map.removeObject();
    };

    return page;
  };

  var history = OSM.History(map),
    note = OSM.Note(map);

  OSM.route = OSM.Router(map, {
    "/":                           OSM.Index(map),
    "/search":                     OSM.Search(map),
    "/export":                     OSM.Export(map),
    "/history":                    history,
    "/new_note":                   OSM.NewNote(map),
    "/user/:display_name/edits":   history,
    "/browse/friends":             history,
    "/browse/nearby":              history,
    "/browse/note/:id":            note,
    "/browse/:type/:id(/history)": OSM.Browse(map)
  });

  OSM.route.load();

  $(document).on("click", "a", function(e) {
    if (e.isDefaultPrevented() || e.isPropagationStopped()) return;
    if (this.host === window.location.host && OSM.route(this.pathname + this.search + this.hash)) e.preventDefault();
  });

  $(".search_form").on("submit", function(e) {
    e.preventDefault();
    $("header").addClass("closed");
    var query = $(this).find("input[name=query]").val();
    if (query) {
      OSM.route("/search?query=" + encodeURIComponent(query) + OSM.formatHash(map));
    } else {
      OSM.route("/" + OSM.formatHash(map));
    }
  });

  $(".describe_location").on("click", function(e) {
    e.preventDefault();
    var precision = zoomPrecision(map.getZoom());
    OSM.route("/search?query=" + encodeURIComponent(
      map.getCenter().lat.toFixed(precision) + "," +
      map.getCenter().lng.toFixed(precision)));
  });
});
