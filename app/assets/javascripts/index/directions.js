//= require ./directions-endpoint
//= require ./directions-route-output
//= require_self
//= require_tree ./directions

OSM.Directions = function (map) {
  let controller = null; // the AbortController for the current route request if a route request is in progress
  let lastLocation = [];
  let chosenEngine;

  let sidebarReadyPromise = null;

  const routeOutput = OSM.DirectionsRouteOutput(map);

  const endpointDragCallback = function (dragging) {
    if (!routeOutput.isVisible()) return;
    if (dragging && !chosenEngine.draggable) return;
    if (dragging && controller) return;

    getRoute(false, !dragging);
  };
  const endpointChangeCallback = function () {
    getRoute(true, true);
  };

  const endpoints = [
    OSM.DirectionsEndpoint(map, $("input[name='route_from']"), { icon: "start", color: "var(--marker-green)" }, endpointDragCallback, endpointChangeCallback),
    OSM.DirectionsEndpoint(map, $("input[name='route_to']"), { icon: "destination", color: "var(--marker-red)" }, endpointDragCallback, endpointChangeCallback)
  ];

  const expires = new Date();

  expires.setFullYear(expires.getFullYear() + 10);

  const modeGroup = $(".routing_modes");
  const select = $("select#routing_engines");

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
    $(".search_form input[name='query']").val(endpoints[1].value);
    OSM.router.route("/" + OSM.formatHash(map));
  });

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
        return !modes.includes(this.value);
      })
      .prop("checked", function () {
        return this.value === chosenEngine.mode;
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

    $("#directions_loader").prop("hidden", false);
    $("#directions_error").prop("hidden", true).empty();
    $("#directions_route").prop("hidden", true);
    map.setSidebarOverlaid(false);
    controller = new AbortController();
    chosenEngine.getRoute(points, controller.signal).then(async function (route) {
      await sidebarLoaded();
      $("#directions_route").prop("hidden", false);
      routeOutput.write(route);

      if (fitRoute) {
        routeOutput.fit();
      }
    }).catch(async function (error) {
      if (error.name === "AbortError") return;

      await sidebarLoaded();
      routeOutput.remove();

      if (reportErrors) {
        $("#directions_error")
          .prop("hidden", false)
          .html("<div class=\"alert alert-danger\">" + OSM.i18n.t("javascripts.directions.errors.no_route") + "</div>");
      }
    }).finally(function () {
      $("#directions_loader").prop("hidden", true);
      controller = null;
    });
  }

  function closeButtonListener(e) {
    e.stopPropagation();
    routeOutput.remove();
    sidebarReadyPromise = null;
    map.setSidebarOverlaid(true);
  }

  setEngine("fossgis_osrm_car");
  setEngine(OSM.cookies.get("_osm_directions_engine"));

  modeGroup.on("change", "input[name='modes']", function (e) {
    setEngine(chosenEngine.provider + "_" + e.target.value);
    OSM.cookies.set("_osm_directions_engine", chosenEngine.id, { expires });
    getRoute(true, true);
  });

  select.on("change", function (e) {
    setEngine(e.target.value + "_" + chosenEngine.mode);
    OSM.cookies.set("_osm_directions_engine", chosenEngine.id, { expires });
    getRoute(true, true);
  });

  $(".directions_form").on("submit", function (e) {
    e.preventDefault();
    getRoute(true, true);
  });

  $(".routing_marker_column span").on("dragstart", function (e) {
    const dt = e.originalEvent.dataTransfer;

    dt.effectAllowed = "move";

    const jqthis = $(this);

    dt.setData("text", JSON.stringify(jqthis.data()));

    if (dt.setDragImage) {
      const img = jqthis.clone()
        .appendTo(document.body);

      img.find("svg")
        .toggleClass("position-absolute bottom-100 end-100")
        .attr({ width: "25", height: "40" });
      dt.setDragImage(img.get(0), 12, 21);
      setTimeout(() => img.remove(), 0);
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
    $("#sidebar .sidebar-close-controls button").on("click", closeButtonListener);

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

  function sidebarLoaded() {
    if ($("#directions_route").length) {
      sidebarReadyPromise = null;

      return Promise.resolve();
    }

    if (sidebarReadyPromise) return sidebarReadyPromise;

    sidebarReadyPromise = new Promise(resolve => OSM.loadSidebarContent("/directions", resolve));

    return sidebarReadyPromise;
  }

  page.pushstate = page.popstate = page.load = function () {
    initializeFromParams();

    $(".search_form").hide();
    $(".directions_form").show();

    sidebarLoaded().then(enableListeners);

    map.setSidebarOverlaid(!endpoints[0].latlng || !endpoints[1].latlng);
  };

  page.unload = function () {
    $(".search_form").show();
    $(".directions_form").hide();

    $("#sidebar .sidebar-close-controls button").off("click", closeButtonListener);
    $("#map").off("dragend dragover drop");
    map.off("locationfound", sendstartinglocation);

    endpoints[0].disableListeners();
    endpoints[1].disableListeners();

    endpoints[0].clearValue();
    endpoints[1].clearValue();

    routeOutput.remove();

    sidebarReadyPromise = null;
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
