//= require ./directions-endpoint
//= require_self
//= require_tree ./directions

OSM.Directions = function (map) {
  let controller = null; // the AbortController for the current route request if a route request is in progress
  let lastLocation = [];
  let chosenEngine;

  const popup = L.popup({ autoPanPadding: [100, 100] });

  const polyline = L.polyline([], {
    color: "#03f",
    opacity: 0.3,
    weight: 10
  });

  const highlight = L.polyline([], {
    color: "#ff0",
    opacity: 0.5,
    weight: 12
  });

  const endpointDragCallback = function (dragging) {
    if (!map.hasLayer(polyline)) return;
    if (dragging && !chosenEngine.draggable) return;
    if (dragging && controller) return;

    getRoute(false, !dragging);
  };
  const endpointChangeCallback = function () {
    getRoute(true, true);
  };

  const endpoints = [
    OSM.DirectionsEndpoint(map, $("input[name='route_from']"), OSM.MARKER_GREEN, endpointDragCallback, endpointChangeCallback),
    OSM.DirectionsEndpoint(map, $("input[name='route_to']"), OSM.MARKER_RED, endpointDragCallback, endpointChangeCallback)
  ];

  let downloadURL = null;

  const expiry = new Date();
  expiry.setYear(expiry.getFullYear() + 10);

  const modeGroup = $(".routing_modes");
  const select = $("select.routing_engines");

  $(".directions_form .reverse_directions").on("click", function () {
    const coordFrom = endpoints[0].latlng,
          coordTo = endpoints[1].latlng;
    let routeFrom = "",
        routeTo = "";
    if (coordFrom) {
      routeFrom = coordFrom.lat + "," + coordFrom.lng;
    }
    if (coordTo) {
      routeTo = coordTo.lat + "," + coordTo.lng;
    }
    endpoints[0].swapCachedReverseGeocodes(endpoints[1]);

    OSM.router.route("/directions?" + new URLSearchParams({
      route: routeTo + ";" + routeFrom
    }));
  });

  $(".directions_form .btn-close").on("click", function (e) {
    e.preventDefault();
    $(".describe_location").toggle(!endpoints[1].value);
    $(".search_form input[name='query']").val(endpoints[1].value);
    OSM.router.route("/" + OSM.formatHash(map));
  });

  function formatTotalDistance(m) {
    if (m < 1000) {
      return OSM.i18n.t("javascripts.directions.distance_m", { distance: Math.round(m) });
    } else if (m < 10000) {
      return OSM.i18n.t("javascripts.directions.distance_km", { distance: (m / 1000.0).toFixed(1) });
    } else {
      return OSM.i18n.t("javascripts.directions.distance_km", { distance: Math.round(m / 1000) });
    }
  }

  function formatStepDistance(m) {
    if (m < 5) {
      return "";
    } else if (m < 200) {
      return OSM.i18n.t("javascripts.directions.distance_m", { distance: String(Math.round(m / 10) * 10) });
    } else if (m < 1500) {
      return OSM.i18n.t("javascripts.directions.distance_m", { distance: String(Math.round(m / 100) * 100) });
    } else if (m < 5000) {
      return OSM.i18n.t("javascripts.directions.distance_km", { distance: String(Math.round(m / 100) / 10) });
    } else {
      return OSM.i18n.t("javascripts.directions.distance_km", { distance: String(Math.round(m / 1000)) });
    }
  }

  function formatHeight(m) {
    return OSM.i18n.t("javascripts.directions.distance_m", { distance: Math.round(m) });
  }

  function formatTime(s) {
    let m = Math.round(s / 60);
    const h = Math.floor(m / 60);
    m -= h * 60;
    return h + ":" + (m < 10 ? "0" : "") + m;
  }

  function setEngine(id) {
    const engines = OSM.Directions.engines;
    const desired = engines.find(engine => engine.id === id);
    if (!desired || (chosenEngine && chosenEngine.id === id)) return;
    chosenEngine = desired;

    const modes = engines
      .filter(engine => engine.provider === chosenEngine.provider)
      .map(engine => engine.mode);
    modeGroup
      .find("input[id]")
      .prop("disabled", function () {
        return !modes.includes(this.id);
      })
      .prop("checked", function () {
        return this.id === chosenEngine.mode;
      });

    const providers = engines
      .filter(engine => engine.mode === chosenEngine.mode)
      .map(engine => engine.provider);
    select
      .find("option[value]")
      .prop("disabled", function () {
        return !providers.includes(this.value);
      });
    select.val(chosenEngine.provider);
  }

  function getRoute(fitRoute, reportErrors) {
    // Cancel any route that is already in progress
    if (controller) controller.abort();

    const points = endpoints.map(p => p.latlng);

    if (!points[0] || !points[1]) return;
    $("header").addClass("closed");

    OSM.router.replace("/directions?" + new URLSearchParams({
      engine: chosenEngine.id,
      route: points.map(p => `${p.lat},${p.lng}`).join(";")
    }));

    // copy loading item to sidebar and display it. we copy it, rather than
    // just using it in-place and replacing it in case it has to be used
    // again.
    $("#directions_content").html($(".directions_form .loader_copy").html());
    map.setSidebarOverlaid(false);
    controller = new AbortController();
    chosenEngine.getRoute(points, controller.signal).then(function (route) {
      polyline
        .setLatLngs(route.line)
        .addTo(map);

      if (fitRoute) {
        map.fitBounds(polyline.getBounds().pad(0.05));
      }

      const distanceText = $("<p>").append(
        OSM.i18n.t("javascripts.directions.distance") + ": " + formatTotalDistance(route.distance) + ". " +
        OSM.i18n.t("javascripts.directions.time") + ": " + formatTime(route.time) + ".");
      if (typeof route.ascend !== "undefined" && typeof route.descend !== "undefined") {
        distanceText.append(
          $("<br>"),
          OSM.i18n.t("javascripts.directions.ascend") + ": " + formatHeight(route.ascend) + ". " +
          OSM.i18n.t("javascripts.directions.descend") + ": " + formatHeight(route.descend) + ".");
      }

      const turnByTurnTable = $("<table class='table table-hover table-sm mb-3'>")
        .append($("<tbody>"));

      $("#directions_content")
        .empty()
        .append(
          distanceText,
          turnByTurnTable
        );

      // Add each row
      route.steps.forEach(function (step) {
        const [ll, direction, instruction, dist, lineseg] = step;

        const row = $("<tr class='turn'/>");
        if (direction) {
          row.append("<td class='border-0'><svg width='20' height='20' class='d-block'><use href='#routing-sprite-" + direction + "' /></svg></td>");
        } else {
          row.append("<td class='border-0'>");
        }
        row.append("<td>" + instruction);
        row.append("<td class='distance text-body-secondary text-end'>" + formatStepDistance(dist));

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

      const blob = new Blob([JSON.stringify(polyline.toGeoJSON())], { type: "application/json" });
      URL.revokeObjectURL(downloadURL);
      downloadURL = URL.createObjectURL(blob);

      $("#directions_content").append(`<p class="text-center"><a href="${downloadURL}" download="${
        OSM.i18n.t("javascripts.directions.filename")
      }">${
        OSM.i18n.t("javascripts.directions.download")
      }</a></p>`);

      $("#directions_content").append("<p class=\"text-center\">" +
        OSM.i18n.t("javascripts.directions.instructions.courtesy", { link: chosenEngine.creditline }) +
        "</p>");
    }).catch(function () {
      map.removeLayer(polyline);
      if (reportErrors) {
        $("#directions_content").html("<div class=\"alert alert-danger\">" + OSM.i18n.t("javascripts.directions.errors.no_route") + "</div>");
      }
    }).finally(function () {
      controller = null;
    });
  }

  function hideRoute(e) {
    e.stopPropagation();
    map.removeLayer(polyline);
    $("#directions_content").html("");
    popup.close();
    map.setSidebarOverlaid(true);
    // TODO: collapse width of sidebar back to previous
  }

  setEngine("fossgis_osrm_car");
  setEngine(Cookies.get("_osm_directions_engine"));

  modeGroup.on("change", "input[name='modes']", function (e) {
    setEngine(chosenEngine.provider + "_" + e.target.id);
    Cookies.set("_osm_directions_engine", chosenEngine.id, { secure: true, expires: expiry, path: "/", samesite: "lax" });
    getRoute(true, true);
  });

  select.on("change", function (e) {
    setEngine(e.target.value + "_" + chosenEngine.mode);
    Cookies.set("_osm_directions_engine", chosenEngine.id, { secure: true, expires: expiry, path: "/", samesite: "lax" });
    getRoute(true, true);
  });

  $(".directions_form").on("submit", function (e) {
    e.preventDefault();
    getRoute(true, true);
  });

  $(".routing_marker_column img").on("dragstart", function (e) {
    const dt = e.originalEvent.dataTransfer;
    dt.effectAllowed = "move";
    const dragData = { type: $(this).data("type") };
    dt.setData("text", JSON.stringify(dragData));
    if (dt.setDragImage) {
      const img = $("<img>").attr("src", $(e.originalEvent.target).attr("src"));
      dt.setDragImage(img.get(0), 12, 21);
    }
  });

  function sendstartinglocation({ latlng: { lat, lng } }) {
    map.fire("startinglocation", { latlng: [lat, lng] });
  }

  function startingLocationListener({ latlng }) {
    if (endpoints[0].value) return;
    endpoints[0].setValue(latlng.join(", "));
  }

  map.on("locationfound", ({ latlng: { lat, lng } }) =>
    lastLocation = [lat, lng]
  ).on("locateactivate", () => {
    map.once("startinglocation", startingLocationListener);
  });

  function initializeFromParams() {
    const params = new URLSearchParams(location.search),
          route = (params.get("route") || "").split(";");

    if (params.has("engine")) setEngine(params.get("engine"));

    endpoints[0].setValue(params.get("from") || route[0] || lastLocation.join(", "));
    endpoints[1].setValue(params.get("to") || route[1] || "");
  }

  function enableListeners() {
    $("#sidebar .sidebar-close-controls button").on("click", hideRoute);

    $("#map").on("dragend dragover", function (e) {
      e.preventDefault();
    });

    $("#map").on("drop", function (e) {
      e.preventDefault();
      const oe = e.originalEvent;
      const dragData = JSON.parse(oe.dataTransfer.getData("text"));
      const type = dragData.type;
      const pt = L.DomEvent.getMousePosition(oe, map.getContainer()); // co-ordinates of the mouse pointer at present
      pt.y += 20;
      const ll = map.containerPointToLatLng(pt);
      const llWithPrecision = OSM.cropLocation(ll, map.getZoom());
      endpoints[type === "from" ? 0 : 1].setValue(llWithPrecision.join(", "));
    });

    map.on("locationfound", sendstartinglocation);

    endpoints[0].enableListeners();
    endpoints[1].enableListeners();
  }

  const page = {};

  page.pushstate = page.popstate = function () {
    if ($("#directions_content").length) {
      page.load();
    } else {
      initializeFromParams();

      $(".search_form").hide();
      $(".directions_form").show();

      OSM.loadSidebarContent("/directions", enableListeners);

      map.setSidebarOverlaid(!endpoints[0].latlng || !endpoints[1].latlng);
    }
  };

  page.load = function () {
    initializeFromParams();

    $(".search_form").hide();
    $(".directions_form").show();

    enableListeners();

    map.setSidebarOverlaid(!endpoints[0].latlng || !endpoints[1].latlng);
  };

  page.unload = function () {
    $(".search_form").show();
    $(".directions_form").hide();

    $("#sidebar .sidebar-close-controls button").off("click", hideRoute);
    $("#map").off("dragend dragover drop");
    map.off("locationfound", sendstartinglocation);

    endpoints[0].disableListeners();
    endpoints[1].disableListeners();

    endpoints[0].clearValue();
    endpoints[1].clearValue();

    map
      .removeLayer(popup)
      .removeLayer(polyline);
  };

  return page;
};

OSM.Directions.engines = [];

OSM.Directions.addEngine = function (engine, supportsHTTPS) {
  if (location.protocol === "http:" || supportsHTTPS) {
    engine.id = engine.provider + "_" + engine.mode;
    OSM.Directions.engines.push(engine);
  }
};
