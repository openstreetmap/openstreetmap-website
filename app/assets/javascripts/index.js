//= require_self
//= require numbered_pagination
//= require leaflet.sidebar
//= require leaflet.sidebar-pane
//= require leaflet.locate
//= require leaflet.layers
//= require leaflet.legend
//= require leaflet.note
//= require leaflet.share
//= require leaflet.query
//= require index/contextmenu
//= require index/initializations
//= require index/layers/data
//= require index/layers/notes
//= require router

OSM.initializations = [];

$(function () {
  const map = new L.OSM.Map("map", {
    zoomControl: false,
    layerControl: false,
    contextmenu: true,
    worldCopyJump: true
  });

  OSM.loadSidebarContent = function (path, callback) {
    const atomSelector = "link[type=\"application/atom+xml\"]";
    let content_path = path;

    map.setSidebarOverlaid(false);

    $("#sidebar_loader").prop("hidden", false).addClass("delayed-fade-in");

    // Prevent caching the XHR response as a full-page URL
    // https://github.com/openstreetmap/openstreetmap-website/issues/5663
    if (content_path.indexOf("?") >= 0) {
      content_path += "&xhr=1";
    } else {
      content_path += "?xhr=1";
    }

    $("#sidebar_content")
      .empty();

    fetch(content_path, { headers: { "accept": "text/html", "x-requested-with": "XMLHttpRequest" } })
      .then(response => {
        $("#flash").empty();
        $("#sidebar_loader").removeClass("delayed-fade-in").prop("hidden", true);

        const title = response.headers.get("X-Page-Title");
        if (title) document.title = decodeURIComponent(title);

        return response.text();
      })
      .then(html => {
        const content = $(html);

        $("head").find(atomSelector).remove();

        $("head").append(content.filter(atomSelector));

        $("#sidebar_content").html(content.not(atomSelector));

        if (callback) {
          callback();
        }
      });
  };

  const token = $("head").data("oauthToken");
  if (token) OSM.oauth = { authorization: "Bearer " + token };

  const params = OSM.mapParams();

  map.attributionControl.setPrefix("");

  map.updateLayers(params.layers);

  map.on("baselayerchange", function (e) {
    if (map.getZoom() > e.layer.options.maxZoom) {
      map.setView(map.getCenter(), e.layer.options.maxZoom, { reset: true });
    }
  });

  const sidebar = L.OSM.sidebar("#map-ui")
    .addTo(map);

  const position = $("html").attr("dir") === "rtl" ? "topleft" : "topright";

  function addControlGroup(controls) {
    for (const control of controls) control.addTo(map);

    const firstContainer = controls[0].getContainer();
    $(firstContainer).find(".control-button").first()
      .addClass("control-button-first");

    const lastContainer = controls[controls.length - 1].getContainer();
    $(lastContainer).find(".control-button").last()
      .addClass("control-button-last");
  }

  addControlGroup([
    L.OSM.zoom({ position }),
    L.OSM.locate({ position })
  ]);

  addControlGroup([
    L.OSM.layers({
      position,
      sidebar,
      layers: map.baseLayers
    }),
    L.OSM.legend({ position, sidebar }),
    L.OSM.share({
      position,
      sidebar,
      "short": true
    })
  ]);

  addControlGroup([
    L.OSM.note({ position, sidebar })
  ]);

  addControlGroup([
    L.OSM.query({ position, sidebar })
  ]);

  L.control.scale()
    .addTo(map);

  OSM.initializations.forEach(func => func(map));

  if (OSM.STATUS !== "api_offline" && OSM.STATUS !== "database_offline") {
    OSM.initializeNotesLayer(map);
    if (params.layers.indexOf(map.noteLayer.options.code) >= 0) {
      map.addLayer(map.noteLayer);
    }

    OSM.initializeDataLayer(map);
    if (params.layers.indexOf(map.dataLayer.options.code) >= 0) {
      map.addLayer(map.dataLayer);
    }

    if (params.layers.indexOf(map.gpsLayer.options.code) >= 0) {
      map.addLayer(map.gpsLayer);
    }
  }

  $(".leaflet-control .control-button").tooltip({ placement: "left", container: "body" });

  const expires = new Date();
  const thisYear = expires.getFullYear();
  expires.setFullYear(thisYear + 10);

  const updateCookieAndLinks = function () {
    updateLinks(
      map.getCenter().wrap(),
      map.getZoom(),
      map.getLayersCode(),
      map._object);

    OSM.cookies.set("_osm_location", OSM.locationCookie(map), { expires });
  };
  for (const e of ["moveend", "baselayerchange", "overlayadd", "overlayremove"]) {
    map.on(e, updateCookieAndLinks);
  }

  if (OSM.cookies.get("_osm_welcome") !== "hide") {
    $(".welcome").addClass("d-md-block");
  }

  $(".welcome .btn-close").on("click", function () {
    $(".welcome").removeClass("d-md-block");
    OSM.cookies.set("_osm_welcome", "hide", { expires });
  });

  expires.setFullYear(thisYear + 1);

  $("#banner .btn-close").on("click", function (e) {
    const cookieId = e.target.id;
    $("#banner").removeClass("d-md-block");
    e.preventDefault();
    if (cookieId) {
      OSM.cookies.set(cookieId, "hide", { expires });
    }
  });

  if (OSM.MATOMO) {
    const matomoLayerHandler = function (e) {
      if (e.layer.options) {
        const goal = OSM.MATOMO.goals[e.layer.options.layerId];

        if (goal) {
          $("body").trigger("matomogoal", goal);
        }
      }
    };
    map.on("baselayerchange", matomoLayerHandler);
    map.on("overlayadd", matomoLayerHandler);
  }

  if (params.bounds) {
    map.fitBounds(params.bounds);
  } else {
    map.setView([params.lat, params.lon], params.zoom);
  }

  if (params.marker && params.mrad) {
    L.circle([params.mlat, params.mlon], { radius: params.mrad }).addTo(map);
  } else if (params.marker) {
    L.marker([params.mlat, params.mlon], { icon: OSM.getMarker({ color: "var(--marker-blue)" }) }).addTo(map);
  }

  function remoteEditHandler(bbox, object) {
    const remoteEditHost = "http://127.0.0.1:8111",
          osmHost = location.protocol + "//" + location.host,
          query = new URLSearchParams({
            left: bbox.getWest() - 0.0001,
            top: bbox.getNorth() + 0.0001,
            right: bbox.getEast() + 0.0001,
            bottom: bbox.getSouth() - 0.0001
          });

    if (object && object.type !== "note") query.set("select", object.type + object.id); // can't select notes
    sendRemoteEditCommand(remoteEditHost + "/load_and_zoom?" + query)
      .then(() => {
        if (object && object.type === "note") {
          const noteQuery = new URLSearchParams({ url: osmHost + OSM.apiUrl(object) });
          sendRemoteEditCommand(remoteEditHost + "/import?" + noteQuery);
        }
      })
      .catch(() => {
        OSM.showAlert(OSM.i18n.t("javascripts.remote_edit.failed.title"),
                      OSM.i18n.t("javascripts.remote_edit.failed.body"));
      });

    function sendRemoteEditCommand(url) {
      return fetch(url, { mode: "no-cors", signal: AbortSignal.timeout(5000) });
    }

    return false;
  }

  $("a[data-editor=remote]").click(function (e) {
    const params = OSM.mapParams(this.search);
    remoteEditHandler(map.getBounds(), params.object);
    e.preventDefault();
  });

  if (new URLSearchParams(location.search).get("edit_help")) {
    $("#editanchor")
      .removeAttr("title")
      .tooltip({
        placement: "bottom",
        title: OSM.i18n.t("javascripts.edit_help")
      })
      .tooltip("show");

    $("body").one("click", function () {
      $("#editanchor").tooltip("hide");
    });
  }

  OSM.router = OSM.Router(map, {
    "/": "index",
    "/search": "search",
    "/directions": "directions",
    "/export": "export",
    "/note/new": "new_note",
    "/history/friends": "history",
    "/history/nearby": "history",
    "/history": "history",
    "/user/:display_name/history": "history",
    "/note/:id": "note",
    "/node/:id(/history)": { module: "index_element", part: m => m.mappedElement("node") },
    "/node/:id/history/:version": { module: "index_element", part: m => m.mappedElement("node") },
    "/way/:id(/history)": { module: "index_element", part: m => m.mappedElement("way") },
    "/way/:id/history/:version": { module: "index_element", part: m => m.element("way") },
    "/relation/:id(/history)": { module: "index_element", part: m => m.mappedElement("relation") },
    "/relation/:id/history/:version": { module: "index_element", part: m => m.element("relation") },
    "/changeset/:id": "changeset",
    "/query": "query",
    "/account/home": "home"
  });

  if (OSM.preferred_editor === "remote" && location.pathname === "/edit") {
    remoteEditHandler(map.getBounds(), params.object);
    OSM.router.setCurrentPath("/");
  }

  OSM.router.load();

  $(document).on("click", "a", function (e) {
    if (e.isDefaultPrevented() || e.isPropagationStopped() || $(e.target).data("turbo")) {
      return;
    }

    // Open links in a new tab as normal.
    if (e.which > 1 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) {
      return;
    }

    // Open local anchor links as normal.
    if ($(this).attr("href")?.startsWith("#")) {
      return;
    }

    // Ignore cross-protocol and cross-origin links.
    const url = new URL($(this).attr("href"), location);
    if (location.protocol !== url.protocol || location.host !== url.host) {
      return;
    }

    if (OSM.router.route(url.pathname + url.search + url.hash)) {
      e.preventDefault();
      if (url.pathname !== "/directions") {
        $("header").addClass("closed");
      }
    }
  });

  $(document).on("click", "#sidebar .sidebar-close-controls button", function () {
    $(".search_form input[name=query]").val("");
    OSM.router.route("/" + OSM.formatHash(map));
  });
});
