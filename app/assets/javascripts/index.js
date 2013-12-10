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
        $('#flash').empty();
        $('#sidebar_loader').hide();

        var content = $(xhr.responseText);

        if (xhr.getResponseHeader('X-Page-Title')) {
          var title = xhr.getResponseHeader('X-Page-Title');
          document.title = decodeURIComponent(escape(title));
        }

        $('head')
          .find('link[type="application/atom+xml"]')
          .remove();

        $('head')
          .append(content.filter('link[type="application/atom+xml"]'));

        $('#sidebar_content').html(content.not('link[type="application/atom+xml"]'));

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

  var expiry = new Date();
  expiry.setYear(expiry.getFullYear() + 10);

  map.on('moveend layeradd layerremove', function() {
    updateLinks(
      map.getCenter().wrap(),
      map.getZoom(),
      map.getLayersCode(),
      map._object);

    $.cookie("_osm_location", cookieContent(map), { expires: expiry });
  });

  if ($.cookie('_osm_welcome') == 'hide') {
    $('.welcome').hide();
  }

  $('.welcome .close').on('click', function() {
    $('.welcome').hide();
    $.cookie("_osm_welcome", 'hide', { expires: expiry });
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
    var params = OSM.mapParams(this.search);
    remoteEditHandler(map.getBounds(), params.object);
    e.preventDefault();
  });

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

    page.pushstate = function() {
      $("#content").addClass("overlay-sidebar");
      map.invalidateSize({pan: false})
        .panBy([-350, 0], {animate: false});
      document.title = I18n.t('layouts.project_name.title');
    };

    page.load = function() {
      if (!("autofocus" in document.createElement("input"))) {
        $(".search_form input[name=query]").focus();
      }
      return map.getState();
    };

    page.popstate = function() {
      $("#content").addClass("overlay-sidebar");
      map.invalidateSize({pan: false});
      document.title = I18n.t('layouts.project_name.title');
    };

    page.unload = function() {
      map.panBy([350, 0], {animate: false});
      $("#content").removeClass("overlay-sidebar");
      map.invalidateSize({pan: false});
    };

    return page;
  };

  OSM.Browse = function(map, type) {
    var page = {};

    page.pushstate = page.popstate = function(path, id) {
      OSM.loadSidebarContent(path, function() {
        addObject(type, id);
      });
    };

    page.load = function(path, id) {
      addObject(type, id, true);
    };

    function addObject(type, id, center) {
      var bounds = map.addObject({type: type, id: parseInt(id)}, function(bounds) {
        if (!window.location.hash && bounds.isValid()) {
          OSM.router.moveListenerOff();
          map.once('moveend', OSM.router.moveListenerOn);
          if (center || !map.getBounds().contains(bounds)) map.fitBounds(bounds);
        }
      });
    }

    page.unload = function() {
      map.removeObject();
    };

    return page;
  };

  var history = OSM.History(map);

  OSM.router = OSM.Router(map, {
    "/":                           OSM.Index(map),
    "/search":                     OSM.Search(map),
    "/export":                     OSM.Export(map),
    "/note/new":                   OSM.NewNote(map),
    "/history/friends":            history,
    "/history/nearby":             history,
    "/history":                    history,
    "/user/:display_name/history": history,
    "/note/:id":                   OSM.Note(map),
    "/node/:id(/history)":         OSM.Browse(map, 'node'),
    "/way/:id(/history)":          OSM.Browse(map, 'way'),
    "/relation/:id(/history)":     OSM.Browse(map, 'relation'),
    "/changeset/:id":              OSM.Browse(map, 'changeset')
  });

  if (OSM.preferred_editor == "remote" && document.location.pathname == "/edit") {
    remoteEditHandler(map.getBounds(), params.object);
    OSM.router.setCurrentPath("/");
  }

  OSM.router.load();

  $(document).on("click", "a", function(e) {
    if (e.isDefaultPrevented() || e.isPropagationStopped())
      return;

    // Open links in a new tab as normal.
    if (e.which > 1 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey)
      return;

    // Ignore cross-protocol and cross-origin links.
    if (location.protocol !== this.protocol || location.host !== this.host)
      return;

    if (OSM.router.route(this.pathname + this.search + this.hash))
      e.preventDefault();
  });

  $(".search_form").on("submit", function(e) {
    e.preventDefault();
    $("header").addClass("closed");
    var query = $(this).find("input[name=query]").val();
    if (query) {
      OSM.router.route("/search?query=" + encodeURIComponent(query) + OSM.formatHash(map));
    } else {
      OSM.router.route("/" + OSM.formatHash(map));
    }
  });

  $(".describe_location").on("click", function(e) {
    e.preventDefault();
    var precision = zoomPrecision(map.getZoom());
    OSM.router.route("/search?query=" + encodeURIComponent(
      map.getCenter().lat.toFixed(precision) + "," +
      map.getCenter().lng.toFixed(precision)));
  });
});
