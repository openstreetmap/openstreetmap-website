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

  function formatDistance(m) {
    const unitTemplate = "javascripts.directions.distance_";
    if (m < 1000) return I18n.t(unitTemplate + "m", { distance: Math.round(m) });
    if (m < 10000) return I18n.t(unitTemplate + "km", { distance: (m / 1000.0).toFixed(1) });
    return I18n.t(unitTemplate + "km", { distance: Math.round(m / 1000) });
  }

  function formatHeight(m) {
    return I18n.t("javascripts.directions.distance_m", { distance: Math.round(m) });
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
      route: points.map(p => OSM.cropLocation(p, map.getZoom()).join()).join(";")
    }));

    // copy loading item to sidebar and display it. we copy it, rather than
    // just using it in-place and replacing it in case it has to be used
    // again.
    $("#sidebar_content").html($(".directions_form .loader_copy").html());
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
        I18n.t("javascripts.directions.distance") + ": " + formatDistance(route.distance) + ". " +
        I18n.t("javascripts.directions.time") + ": " + formatTime(route.time) + ".");
      if (typeof route.ascend !== "undefined" && typeof route.descend !== "undefined") {
        distanceText.append(
          $("<br>"),
          I18n.t("javascripts.directions.ascend") + ": " + formatHeight(route.ascend) + ". " +
          I18n.t("javascripts.directions.descend") + ": " + formatHeight(route.descend) + ".");
      }

      const turnByTurnTable = $("<table class='table table-hover table-sm mb-3'>")
        .append($("<tbody>"));
      const directionsCloseButton = $("<button type='button' class='btn-close'>")
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
        const [ll, direction, instruction, dist, lineseg] = step;

        const row = $("<tr class='turn'/>");
        row.append("<td class='border-0'><div class='direction i" + direction + "'/></td> ");
        row.append("<td>" + instruction);
        row.append("<td class='distance text-body-secondary text-end'>" + getDistText(dist));

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

      $("#sidebar_content").append(`<p class="text-center"><a href="${downloadURL}" download="${
        I18n.t("javascripts.directions.filename")
      }">${
        I18n.t("javascripts.directions.download")
      }</a></p>`);

      $("#sidebar_content").append("<p class=\"text-center\">" +
        I18n.t("javascripts.directions.instructions.courtesy", { link: chosenEngine.creditline }) +
        "</p>");

      directionsCloseButton.on("click", function () {
        map.removeLayer(polyline);
        $("#sidebar_content").html("");
        popup.close();
        map.setSidebarOverlaid(true);
        // TODO: collapse width of sidebar back to previous
      });
    }).catch(function () {
      map.removeLayer(polyline);
      if (reportErrors) {
        $("#sidebar_content").html("<div class=\"alert alert-danger\">" + I18n.t("javascripts.directions.errors.no_route") + "</div>");
      }
    }).finally(function () {
      controller = null;
    });

    function getDistText(dist) {
      if (dist < 5) return "";
      if (dist < 200) return String(Math.round(dist / 10) * 10) + "m";
      if (dist < 1500) return String(Math.round(dist / 100) * 100) + "m";
      if (dist < 5000) return String(Math.round(dist / 100) / 10) + "km";
      return String(Math.round(dist / 1000)) + "km";
    }
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

  const page = {};

  page.pushstate = page.popstate = function () {
    $(".search_form").hide();
    $(".directions_form").show();

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

    endpoints[0].enable();
    endpoints[1].enable();

    const params = new URLSearchParams(location.search),
          route = (params.get("route") || "").split(";");

    if (params.has("engine")) setEngine(params.get("engine"));

    endpoints[0].setValue(params.get("from") || route[0] || lastLocation.join(", "));
    endpoints[1].setValue(params.get("to") || route[1] || "");

    map.setSidebarOverlaid(!endpoints[0].latlng || !endpoints[1].latlng);
  };

  page.load = function () {
    page.pushstate();
  };

  page.unload = function () {
    $(".search_form").show();
    $(".directions_form").hide();
    $("#map").off("dragend dragover drop");
    map.off("locationfound", sendstartinglocation);

    endpoints[0].disable();
    endpoints[1].disable();

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
