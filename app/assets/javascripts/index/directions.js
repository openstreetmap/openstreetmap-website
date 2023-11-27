//= require_self
//= require_tree ./directions
//= require qs/dist/qs

OSM.Directions = function (map) {
  var awaitingGeocode; // true if the user has requested a route, but we're waiting on a geocode result
  var awaitingRoute; // true if we've asked the engine for a route and are waiting to hear back
  var chosenEngine;

  var popup = L.popup({ autoPanPadding: [100, 100] });

  var polyline = L.polyline([], {
    color: "#03f",
    opacity: 0.3,
    weight: 10
  });

  var highlight = L.polyline([], {
    color: "#ff0",
    opacity: 0.5,
    weight: 12
  });

  var endpoints = [
    Endpoint($("input[name='route_from']"), OSM.MARKER_GREEN),
    Endpoint($("input[name='route_to']"), OSM.MARKER_RED)
  ];

  var expiry = new Date();
  expiry.setYear(expiry.getFullYear() + 10);

  var engines = OSM.Directions.engines;

  engines.sort(function (a, b) {
    var localised_a = I18n.t("javascripts.directions.engines." + a.id),
        localised_b = I18n.t("javascripts.directions.engines." + b.id);
    return localised_a.localeCompare(localised_b);
  });

  var select = $("select.routing_engines");

  engines.forEach(function (engine, i) {
    select.append("<option value='" + i + "'>" + I18n.t("javascripts.directions.engines." + engine.id) + "</option>");
  });

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
      draggable: true,
      autoPan: true
    });

    endpoint.marker.on("drag dragend", function (e) {
      var dragging = (e.type === "drag");
      if (dragging && !chosenEngine.draggable) return;
      if (dragging && awaitingRoute) return;
      endpoint.setLatLng(e.target.getLatLng());
      if (map.hasLayer(polyline)) {
        getRoute(false, !dragging);
      }
    });

    input.on("keydown", function () {
      input.removeClass("error");
    });

    input.on("change", function (e) {
      awaitingGeocode = true;

      // make text the same in both text boxes
      var value = e.target.value;
      endpoint.setValue(value);
    });

    endpoint.setValue = function (value, latlng) {
      endpoint.value = value;
      delete endpoint.latlng;
      input.removeClass("error");
      input.val(value);

      if (latlng) {
        endpoint.setLatLng(latlng);
      } else {
        endpoint.getGeocode();
      }
    };

    endpoint.getGeocode = function () {
      // if no one has entered a value yet, then we can't geocode, so don't
      // even try.
      if (!endpoint.value) {
        return;
      }

      endpoint.awaitingGeocode = true;

      var viewbox = map.getBounds().toBBoxString(); // <sw lon>,<sw lat>,<ne lon>,<ne lat>

      $.getJSON(OSM.NOMINATIM_URL + "search?q=" + encodeURIComponent(endpoint.value) + "&format=json&viewbox=" + viewbox, function (json) {
        endpoint.awaitingGeocode = false;
        endpoint.hasGeocode = true;
        if (json.length === 0) {
          input.addClass("error");
          alert(I18n.t("javascripts.directions.errors.no_place", { place: endpoint.value }));
          return;
        }

        endpoint.setLatLng(L.latLng(json[0]));

        input.val(json[0].display_name);

        if (awaitingGeocode) {
          awaitingGeocode = false;
          getRoute(true, true);
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

  $(".directions_form .reverse_directions").on("click", function () {
    var coordFrom = endpoints[0].latlng,
        coordTo = endpoints[1].latlng,
        routeFrom = "",
        routeTo = "";
    if (coordFrom) {
      routeFrom = coordFrom.lat + "," + coordFrom.lng;
    }
    if (coordTo) {
      routeTo = coordTo.lat + "," + coordTo.lng;
    }

    OSM.router.route("/directions?" + Qs.stringify({
      from: $("#route_to").val(),
      to: $("#route_from").val(),
      route: routeTo + ";" + routeFrom
    }));
  });

  $(".directions_form .btn-close").on("click", function (e) {
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
      return I18n.t("javascripts.directions.distance_m", { distance: Math.round(m) });
    } else if (m < 10000) {
      return I18n.t("javascripts.directions.distance_km", { distance: (m / 1000.0).toFixed(1) });
    } else {
      return I18n.t("javascripts.directions.distance_km", { distance: Math.round(m / 1000) });
    }
  }

  function formatHeight(m) {
    return I18n.t("javascripts.directions.distance_m", { distance: Math.round(m) });
  }

  function formatTime(s) {
    var m = Math.round(s / 60);
    var h = Math.floor(m / 60);
    m -= h * 60;
    return h + ":" + (m < 10 ? "0" : "") + m;
  }

  function findEngine(id) {
    return engines.findIndex(function (engine) {
      return engine.id === id;
    });
  }

  function setEngine(index) {
    chosenEngine = engines[index];
    select.val(index);
  }

  function getRoute(fitRoute, reportErrors) {
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

    OSM.router.replace("/directions?" + Qs.stringify({
      engine: chosenEngine.id,
      route: o.lat.toFixed(precision) + "," + o.lng.toFixed(precision) + ";" +
             d.lat.toFixed(precision) + "," + d.lng.toFixed(precision)
    }));

    // copy loading item to sidebar and display it. we copy it, rather than
    // just using it in-place and replacing it in case it has to be used
    // again.
    $("#sidebar_content").html($(".directions_form .loader_copy").html());
    map.setSidebarOverlaid(false);

    awaitingRoute = chosenEngine.getRoute([o, d], function (err, route) {
      awaitingRoute = null;

      if (err) {
        map.removeLayer(polyline);

        if (reportErrors) {
          $("#sidebar_content").html("<div class=\"alert alert-danger\">" + I18n.t("javascripts.directions.errors.no_route") + "</div>");
        }

        return;
      }

      polyline
        .setLatLngs(route.line)
        .addTo(map);

      if (fitRoute) {
        map.fitBounds(polyline.getBounds().pad(0.05));
      }

      var distanceText = $("<p>").append(
        I18n.t("javascripts.directions.distance") + ": " + formatDistance(route.distance) + ". " +
        I18n.t("javascripts.directions.time") + ": " + formatTime(route.time) + ".");
      if (typeof route.ascend !== "undefined" && typeof route.descend !== "undefined") {
        distanceText.append(
          $("<br>"),
          I18n.t("javascripts.directions.ascend") + ": " + formatHeight(route.ascend) + ". " +
          I18n.t("javascripts.directions.descend") + ": " + formatHeight(route.descend) + ".");
      }

      var turnByTurnTable = $("<table class='table table-sm mb-3'>")
        .append($("<tbody>"));
      var directionsCloseButton = $("<button type='button' class='btn-close'>")
        .attr("aria-label", I18n.t("javascripts.close"));

      $("#sidebar_content")
        .empty()
        .append(
          $("<div class='d-flex'>").append(
            $("<h2 class='flex-grow-1 text-break'>")
              .text(I18n.t("javascripts.directions.directions")),
            $("<div>").append(directionsCloseButton)),
          distanceText,
          turnByTurnTable
        );

      // Add each row
      route.steps.forEach(function (step) {
        var ll = step[0],
            direction = step[1],
            instruction = step[2],
            dist = step[3],
            lineseg = step[4];

        if (dist < 5) {
          dist = "";
        } else if (dist < 200) {
          dist = String(Math.round(dist / 10) * 10) + "m";
        } else if (dist < 1500) {
          dist = String(Math.round(dist / 100) * 100) + "m";
        } else if (dist < 5000) {
          dist = String(Math.round(dist / 100) / 10) + "km";
        } else {
          dist = String(Math.round(dist / 1000)) + "km";
        }

        var row = $("<tr class='turn'/>");
        row.append("<td class='border-0'><div class='direction i" + direction + "'/></td> ");
        row.append("<td>" + instruction);
        row.append("<td class='distance text-muted text-end'>" + dist);

        row.on("click", function () {
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

        turnByTurnTable.append(row);
      });

      $("#sidebar_content").append("<p class=\"text-center\">" +
        I18n.t("javascripts.directions.instructions.courtesy", { link: chosenEngine.creditline }) +
        "</p>");

      directionsCloseButton.on("click", function () {
        map.removeLayer(polyline);
        $("#sidebar_content").html("");
        map.setSidebarOverlaid(true);
        // TODO: collapse width of sidebar back to previous
      });
    });
  }

  var chosenEngineIndex = findEngine("fossgis_osrm_car");
  if (Cookies.get("_osm_directions_engine")) {
    chosenEngineIndex = findEngine(Cookies.get("_osm_directions_engine"));
  }
  setEngine(chosenEngineIndex);

  select.on("change", function (e) {
    chosenEngine = engines[e.target.selectedIndex];
    Cookies.set("_osm_directions_engine", chosenEngine.id, { secure: true, expires: expiry, path: "/", samesite: "lax" });
    getRoute(true, true);
  });

  $(".directions_form").on("submit", function (e) {
    e.preventDefault();
    getRoute(true, true);
  });

  $(".routing_marker").on("dragstart", function (e) {
    var dt = e.originalEvent.dataTransfer;
    dt.effectAllowed = "move";
    var dragData = { type: $(this).data("type") };
    dt.setData("text", JSON.stringify(dragData));
    if (dt.setDragImage) {
      var img = $("<img>").attr("src", $(e.originalEvent.target).attr("src"));
      dt.setDragImage(img.get(0), 12, 21);
    }
  });

  var page = {};

  page.pushstate = page.popstate = function () {
    $(".search_form").hide();
    $(".directions_form").show();

    $("#map").on("dragend dragover", function (e) {
      e.preventDefault();
    });

    $("#map").on("drop", function (e) {
      e.preventDefault();
      var oe = e.originalEvent;
      var dragData = JSON.parse(oe.dataTransfer.getData("text"));
      var type = dragData.type;
      var pt = L.DomEvent.getMousePosition(oe, map.getContainer()); // co-ordinates of the mouse pointer at present
      pt.y += 20;
      var ll = map.containerPointToLatLng(pt);
      endpoints[type === "from" ? 0 : 1].setLatLng(ll);
      getRoute(true, true);
    });

    var params = Qs.parse(location.search.substring(1)),
        route = (params.route || "").split(";"),
        from = route[0] && L.latLng(route[0].split(",")),
        to = route[1] && L.latLng(route[1].split(","));

    if (params.engine) {
      var engineIndex = findEngine(params.engine);

      if (engineIndex >= 0) {
        setEngine(engineIndex);
      }
    }

    endpoints[0].setValue(params.from || "", from);
    endpoints[1].setValue(params.to || "", to);

    map.setSidebarOverlaid(!from || !to);

    getRoute(true, true);
  };

  page.load = function () {
    page.pushstate();
  };

  page.unload = function () {
    $(".search_form").show();
    $(".directions_form").hide();
    $("#map").off("dragend dragover drop");

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
