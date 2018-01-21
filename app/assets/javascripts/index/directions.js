//= require_self
//= require_tree ./directions

OSM.Directions = function (map) {
  var awaitingGeocode; // true if the user has requested a route, but we're waiting on a geocode result
  var awaitingRoute;   // true if we've asked the engine for a route and are waiting to hear back
  var dragging;        // true if the user is dragging a start/end point
  var chosenEngine;

  var popup = L.popup();

  var polyline = L.polyline([], {
    color: '#03f',
    opacity: 0.3,
    weight: 10
  });

  var highlight = L.polyline([], {
    color: '#ff0',
    opacity: 0.5,
    weight: 12
  });

  var endpoints = [
    Endpoint($("input[name='route_from']"), OSM.MARKER_GREEN),
    Endpoint($("input[name='route_to']"), OSM.MARKER_RED)
  ];

  var expiry = new Date();
  expiry.setYear(expiry.getFullYear() + 10);

  function Endpoint(input, iconUrl) {
    var endpoint = {};

    endpoint.marker = L.marker([0, 0], {
      icon: L.icon({
        iconUrl: iconUrl,
        iconSize: [25, 41],
        iconAnchor: [12, 41],
        popupAnchor: [1, -34],
        shadowUrl: OSM.MARKER_SHADOW,
        shadowSize: [41, 41]
      }),
      draggable: true
    });

    endpoint.marker.on('drag dragend', function (e) {
      dragging = (e.type === 'drag');
      if (dragging && !chosenEngine.draggable) return;
      if (dragging && awaitingRoute) return;
      endpoint.setLatLng(e.target.getLatLng());
      if (map.hasLayer(polyline)) {
        getRoute();
      }
    });

    input.on("change", function (e) {
      // make text the same in both text boxes
      var value = e.target.value;
      endpoint.setValue(value);
    });

    endpoint.setValue = function(value) {
      endpoint.value = value;
      delete endpoint.latlng;
      input.val(value);
      endpoint.getGeocode();
    };

    endpoint.getGeocode = function() {
      // if no one has entered a value yet, then we can't geocode, so don't
      // even try.
      if (!endpoint.value) {
        return;
      }

      endpoint.awaitingGeocode = true;

      $.getJSON(OSM.NOMINATIM_URL + 'search?q=' + encodeURIComponent(endpoint.value) + '&format=json', function (json) {
        endpoint.awaitingGeocode = false;
        endpoint.hasGeocode = true;
        if (json.length === 0) {
          alert(I18n.t('javascripts.directions.errors.no_place'));
          return;
        }

        input.val(json[0].display_name);

        endpoint.latlng = L.latLng(json[0]);
        endpoint.marker
          .setLatLng(endpoint.latlng)
          .addTo(map);

        if (awaitingGeocode) {
          awaitingGeocode = false;
          getRoute();
        }
      });
    };

    endpoint.setLatLng = function (ll) {
      var precision = OSM.zoomPrecision(map.getZoom());
      input.val(ll.lat.toFixed(precision) + ", " + ll.lng.toFixed(precision));
      endpoint.hasGeocode = true;
      endpoint.latlng = ll;
      endpoint.marker
        .setLatLng(ll)
        .addTo(map);
    };

    return endpoint;
  }

  $(".directions_form .close").on("click", function(e) {
    e.preventDefault();
    var route_from = endpoints[0].value;
    if (route_from) {
      OSM.router.route("/?query=" + encodeURIComponent(route_from) + OSM.formatHash(map));
    } else {
      OSM.router.route("/" + OSM.formatHash(map));
    }
  });

  function formatDistance(m) {
    if (m < 1000) {
      return Math.round(m) + "m";
    } else if (m < 10000) {
      return (m / 1000.0).toFixed(1) + "km";
    } else {
      return Math.round(m / 1000) + "km";
    }
  }

  function formatTime(s) {
    var m = Math.round(s / 60);
    var h = Math.floor(m / 60);
    m -= h * 60;
    return h + ":" + (m < 10 ? '0' : '') + m;
  }

  function setEngine(id) {
    engines.forEach(function(engine, i) {
      if (engine.id === id) {
        chosenEngine = engine;
        select.val(i);
      }
    });
  }

  function getRoute() {
    // Cancel any route that is already in progress
    if (awaitingRoute) awaitingRoute.abort();

    // go fetch geocodes for any endpoints which have not already
    // been geocoded.
    for (var ep_i = 0; ep_i < 2; ++ep_i) {
      var endpoint = endpoints[ep_i];
      if (!endpoint.hasGeocode && !endpoint.awaitingGeocode) {
        endpoint.getGeocode();
        awaitingGeocode = true;
      }
    }
    if (endpoints[0].awaitingGeocode || endpoints[1].awaitingGeocode) {
      awaitingGeocode = true;
      return;
    }

    var o = endpoints[0].latlng,
        d = endpoints[1].latlng;

    if (!o || !d) return;
    $("header").addClass("closed");

    var precision = OSM.zoomPrecision(map.getZoom());

    OSM.router.replace("/directions?" + querystring.stringify({
      engine: chosenEngine.id,
      route: o.lat.toFixed(precision) + ',' + o.lng.toFixed(precision) + ';' +
             d.lat.toFixed(precision) + ',' + d.lng.toFixed(precision)
    }));

    // copy loading item to sidebar and display it. we copy it, rather than
    // just using it in-place and replacing it in case it has to be used
    // again.
    $('#sidebar_content').html($('.directions_form .loader_copy').html());
    map.setSidebarOverlaid(false);

    awaitingRoute = chosenEngine.getRoute([o, d], function (err, route) {
      awaitingRoute = null;

      if (err) {
        map.removeLayer(polyline);

        if (!dragging) {
          $('#sidebar_content').html('<p class="search_results_error">' + I18n.t('javascripts.directions.errors.no_route') + '</p>');
        }

        return;
      }

      polyline
        .setLatLngs(route.line)
        .addTo(map);

      if (!dragging) {
        map.fitBounds(polyline.getBounds().pad(0.05));
      }

      var html = '<h2><a class="geolink" href="#">' +
        '<span class="icon close"></span></a>' + I18n.t('javascripts.directions.directions') +
        '</h2><p id="routing_summary">' +
        I18n.t('javascripts.directions.distance') + ': ' + formatDistance(route.distance) + '. ' +
        I18n.t('javascripts.directions.time') + ': ' + formatTime(route.time) + '.';
      if (typeof route.ascend !== 'undefined' && typeof route.descend !== 'undefined') {
        html += '<br />' +
          I18n.t('javascripts.directions.ascend') + ': ' + Math.round(route.ascend) + 'm. ' +
          I18n.t('javascripts.directions.descend') + ': ' + Math.round(route.descend) +'m.';
      }
      html += '</p><table id="turnbyturn" />';

      $('#sidebar_content')
        .html(html);

      // Add each row
      var cumulative = 0;
      route.steps.forEach(function (step) {
        var ll        = step[0],
          direction   = step[1],
          instruction = step[2],
          dist        = step[3],
          lineseg     = step[4];

        cumulative += dist;

        if (dist < 5) {
          dist = "";
        } else if (dist < 200) {
          dist = Math.round(dist / 10) * 10 + "m";
        } else if (dist < 1500) {
          dist = Math.round(dist / 100) * 100 + "m";
        } else if (dist < 5000) {
          dist = Math.round(dist / 100) / 10 + "km";
        } else {
          dist = Math.round(dist / 1000) + "km";
        }

        var row = $("<tr class='turn'/>");
        row.append("<td><div class='direction i" + direction + "'/></td> ");
        row.append("<td class='instruction'>" + instruction);
        row.append("<td class='distance'>" + dist);

        row.on('click', function () {
          popup
            .setLatLng(ll)
            .setContent("<p>" + instruction + "</p>")
            .openOn(map);
        });

        row.hover(function () {
          highlight
            .setLatLngs(lineseg)
            .addTo(map);
        }, function () {
          map.removeLayer(highlight);
        });

        $('#turnbyturn').append(row);
      });

      $('#sidebar_content').append('<p id="routing_credit">' +
        I18n.t('javascripts.directions.instructions.courtesy', {link: chosenEngine.creditline}) +
        '</p>');

      $('#sidebar_content a.geolink').on('click', function(e) {
        e.preventDefault();
        map.removeLayer(polyline);
        $('#sidebar_content').html('');
        map.setSidebarOverlaid(true);
        // TODO: collapse width of sidebar back to previous
      });
    });
  }

  var engines = OSM.Directions.engines;

  engines.sort(function (a, b) {
    a = I18n.t('javascripts.directions.engines.' + a.id);
    b = I18n.t('javascripts.directions.engines.' + b.id);
    return a.localeCompare(b);
  });

  var select = $('select.routing_engines');

  engines.forEach(function(engine, i) {
    select.append("<option value='" + i + "'>" + I18n.t('javascripts.directions.engines.' + engine.id) + "</option>");
  });

  var chosenEngineId = $.cookie('_osm_directions_engine');
  if(!chosenEngineId) {
    chosenEngineId = 'osrm_car';
  }
  setEngine(chosenEngineId);

  select.on("change", function (e) {
    chosenEngine = engines[e.target.selectedIndex];
    $.cookie('_osm_directions_engine', chosenEngine.id, { expires: expiry, path: '/' });
    if (map.hasLayer(polyline)) {
      getRoute();
    }
  });

  $(".directions_form").on("submit", function(e) {
    e.preventDefault();
    getRoute();
  });

  $(".routing_marker").on('dragstart', function (e) {
    var dt = e.originalEvent.dataTransfer;
    dt.effectAllowed = 'move';
    var dragData = { type: $(this).data('type') };
    dt.setData('text', JSON.stringify(dragData));
    if (dt.setDragImage) {
      var img = $("<img>").attr("src", $(e.originalEvent.target).attr("src"));
      dt.setDragImage(img.get(0), 12, 21);
    }
  });

  var page = {};

  page.pushstate = page.popstate = function() {
    $(".search_form").hide();
    $(".directions_form").show();

    $("#map").on('dragend dragover', function (e) {
      e.preventDefault();
    });

    $("#map").on('drop', function (e) {
      e.preventDefault();
      var oe = e.originalEvent;
      var dragData = JSON.parse(oe.dataTransfer.getData('text'));
      var type = dragData.type;
      var pt = L.DomEvent.getMousePosition(oe, map.getContainer());  // co-ordinates of the mouse pointer at present
      pt.y += 20;
      var ll = map.containerPointToLatLng(pt);
      endpoints[type === 'from' ? 0 : 1].setLatLng(ll);
      getRoute();
    });

    var params = querystring.parse(location.search.substring(1)),
      route = (params.route || '').split(';');

    if (params.engine) {
      setEngine(params.engine);
    }

    endpoints[0].setValue(params.from || "");
    endpoints[1].setValue(params.to || "");

    var o = route[0] && L.latLng(route[0].split(',')),
        d = route[1] && L.latLng(route[1].split(','));

    if (o) endpoints[0].setLatLng(o);
    if (d) endpoints[1].setLatLng(d);

    map.setSidebarOverlaid(!o || !d);

    getRoute();
  };

  page.load = function() {
    page.pushstate();
  };

  page.unload = function() {
    $(".search_form").show();
    $(".directions_form").hide();
    $("#map").off('dragend dragover drop');

    map
      .removeLayer(popup)
      .removeLayer(polyline)
      .removeLayer(endpoints[0].marker)
      .removeLayer(endpoints[1].marker);
  };

  return page;
};

OSM.Directions.engines = [];

OSM.Directions.addEngine = function (engine, supportsHTTPS) {
  if (document.location.protocol === "http:" || supportsHTTPS) {
    OSM.Directions.engines.push(engine);
  }
};
