//= require_self
//= require leaflet.sidebar
//= require leaflet.locate
//= require leaflet.layers
//= require leaflet.key
//= require leaflet.note
//= require leaflet.share
//= require leaflet.polyline
//= require leaflet.query
//= require leaflet.contextmenu
//= require index/search
//= require index/browse
//= require index/export
//= require index/notes
//= require index/history
//= require index/note
//= require index/new_note
//= require index/directions
//= require index/changeset
//= require index/query
//= require router

$(document).ready(function () {
  var loaderTimeout;

  OSM.loadSidebarContent = function(path, callback) {
    map.setSidebarOverlaid(false);

    clearTimeout(loaderTimeout);

    loaderTimeout = setTimeout(function() {
      $('#sidebar_loader').show();
    }, 200);

    // IE<10 doesn't respect Vary: X-Requested-With header, so
    // prevent caching the XHR response as a full-page URL.
    if (path.indexOf('?') >= 0) {
      path += '&xhr=1';
    } else {
      path += '?xhr=1';
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
          document.title = decodeURIComponent(title);
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

  var params = OSM.mapParams();

  // TODO consider using a separate js file for the context menu additions
  var context_describe = function(e){
    var precision = OSM.zoomPrecision(map.getZoom());
    OSM.router.route("/search?query=" + encodeURIComponent(
      e.latlng.lat.toFixed(precision) + "," + e.latlng.lng.toFixed(precision)
    ));
  };

  var context_directionsfrom = function(e){
    var precision = OSM.zoomPrecision(map.getZoom());
    OSM.router.route("/directions?" + querystring.stringify({
      route: e.latlng.lat.toFixed(precision) + ',' + e.latlng.lng.toFixed(precision) + ';' + $('#route_to').val()
    }));
  }

  var context_directionsto = function(e){
    var precision = OSM.zoomPrecision(map.getZoom());
    OSM.router.route("/directions?" + querystring.stringify({
      route: $('#route_from').val() + ';' + e.latlng.lat.toFixed(precision) + ',' + e.latlng.lng.toFixed(precision)
    }));
  }

  var context_addnote = function(e){
    // I'd like this, instead of panning, to pass a query parameter about where to place the marker
    map.panTo(e.latlng, {animate: false});
    OSM.router.route('/note/new');
  }

  var context_centrehere = function(e){
    map.panTo(e.latlng);
  }

  var context_queryhere = function(e) {
    var precision = OSM.zoomPrecision(map.getZoom()),
      latlng = e.latlng.wrap(),
      lat = latlng.lat.toFixed(precision),
      lng = latlng.lng.toFixed(precision);

    OSM.router.route("/query?lat=" + lat + "&lon=" + lng);
  }

  // TODO internationalisation of the context menu strings
  var map = new L.OSM.Map("map", {
    zoomControl: false,
    layerControl: false,
    contextmenu: true,
    contextmenuWidth: 140,
    contextmenuItems: [{
        text: 'Directions from here',
        callback: context_directionsfrom
    }, {
        text: 'Directions to here',
        callback: context_directionsto
    }, '-', {
        text: 'Add a note here',
        callback: context_addnote
    }, {
        text: 'Show address',
        callback: context_describe
    }, {
        text: 'Query features',
        callback: context_queryhere
    }, {
        text: 'Centre map here',
        callback: context_centrehere
    }]
  });

  $(document).on('mousedown', function(e){
    if(e.shiftKey){
      map.contextmenu.disable(); // on firefox, shift disables our contextmenu. we explicitly do this for all browsers.
    }else{
      map.contextmenu.enable();
      // we also decide whether to disable some options that only like high zoom
      map.contextmenu.setDisabled(3, map.getZoom() < 12);
      map.contextmenu.setDisabled(5, map.getZoom() < 14);
    }
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

  L.OSM.query({
    position: position,
    sidebar: sidebar
  }).addTo(map);

  L.control.scale()
    .addTo(map);

  if (OSM.STATUS !== 'api_offline' && OSM.STATUS !== 'database_offline') {
    OSM.initializeNotes(map);
    if (params.layers.indexOf(map.noteLayer.options.code) >= 0) {
      map.addLayer(map.noteLayer);
    }

    OSM.initializeBrowse(map);
    if (params.layers.indexOf(map.dataLayer.options.code) >= 0) {
      map.addLayer(map.dataLayer);
    }
  }

  var placement = $('html').attr('dir') === 'rtl' ? 'right' : 'left';
  $('.leaflet-control .control-button').tooltip({placement: placement, container: 'body'});

  var expiry = new Date();
  expiry.setYear(expiry.getFullYear() + 10);

  map.on('moveend layeradd layerremove', function() {
    updateLinks(
      map.getCenter().wrap(),
      map.getZoom(),
      map.getLayersCode(),
      map._object);

    $.removeCookie("_osm_location");
    $.cookie("_osm_location", OSM.locationCookie(map), { expires: expiry, path: "/" });
  });

  if ($.cookie('_osm_welcome') === 'hide') {
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

  var marker = L.marker([0, 0], {icon: OSM.getUserIcon()});

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

  function remoteEditHandler(bbox, object) {
    var loaded = false,
        url = document.location.protocol === "https:" ?
        "https://127.0.0.1:8112/load_and_zoom?" :
        "http://127.0.0.1:8111/load_and_zoom?",
        query = {
          left: bbox.getWest() - 0.0001,
          top: bbox.getNorth() + 0.0001,
          right: bbox.getEast() + 0.0001,
          bottom: bbox.getSouth() - 0.0001
        };

    if (object) query.select = object.type + object.id;

    var iframe = $('<iframe>')
        .hide()
        .appendTo('body')
        .attr("src", url + querystring.stringify(query))
        .on('load', function() {
          $(this).remove();
          loaded = true;
        });

    setTimeout(function () {
      if (!loaded) {
        alert(I18n.t('site.index.remote_failed'));
        iframe.remove();
      }
    }, 1000);

    return false;
  }

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

    page.pushstate = page.popstate = function() {
      map.setSidebarOverlaid(true);
      document.title = I18n.t('layouts.project_name.title');
    };

    page.load = function() {
      var params = querystring.parse(location.search.substring(1));
      if (params.query) {
        $("#sidebar .search_form input[name=query]").value(params.query);
      }
      if (!("autofocus" in document.createElement("input"))) {
        $("#sidebar .search_form input[name=query]").focus();
      }
      return map.getState();
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
      map.addObject({type: type, id: parseInt(id)}, function(bounds) {
        if (!window.location.hash && bounds.isValid() &&
            (center || !map.getBounds().contains(bounds))) {
          OSM.router.withoutMoveListener(function () {
            map.fitBounds(bounds);
          });
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
    "/directions":                 OSM.Directions(map),
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
    "/changeset/:id":              OSM.Changeset(map),
    "/query":                      OSM.Query(map)
  });

  if (OSM.preferred_editor === "remote" && document.location.pathname === "/edit") {
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
});
