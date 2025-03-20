//= require_self
//= require leaflet.sidebar
//= require leaflet.sidebar-pane
//= require leaflet.locatecontrol/dist/L.Control.Locate.umd
//= require leaflet.locate
//= require leaflet.layers
//= require leaflet.key
//= require leaflet.note
//= require leaflet.share
//= require leaflet.polyline
//= require leaflet.query
//= require leaflet.contextmenu
//= require index/contextmenu
//= require index/search
//= require index/layers/data
//= require index/export
//= require index/layers/notes
//= require index/history
//= require index/note
//= require index/new_note
//= require index/directions
//= require index/changeset
//= require index/query
//= require index/home
//= require router

$(function () {
  const map = new L.OSM.Map("map", {
    zoomControl: false,
    layerControl: false,
    contextmenu: true,
    worldCopyJump: true
  });

  OSM.loadSidebarContent = function (path, callback) {
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

        $("head")
          .find("link[type=\"application/atom+xml\"]")
          .remove();

        $("head")
          .append(content.filter("link[type=\"application/atom+xml\"]"));

        $("#sidebar_content").html(content.not("link[type=\"application/atom+xml\"]"));

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
    L.OSM.zoom({ position: position }),
    L.OSM.locate({ position: position })
  ]);

  addControlGroup([
    L.OSM.layers({
      position: position,
      layers: map.baseLayers,
      sidebar: sidebar
    }),
    L.OSM.key({
      position: position,
      sidebar: sidebar
    }),
    L.OSM.share({
      "position": position,
      "sidebar": sidebar,
      "short": true
    })
  ]);

  addControlGroup([
    L.OSM.note({
      position: position,
      sidebar: sidebar
    })
  ]);

  addControlGroup([
    L.OSM.query({
      position: position,
      sidebar: sidebar
    })
  ]);

  L.control.scale()
    .addTo(map);

  OSM.initializeContextMenu(map);

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

  const expiry = new Date();
  expiry.setYear(expiry.getFullYear() + 10);

  map.on("moveend baselayerchange overlayadd overlayremove", function () {
    updateLinks(
      map.getCenter().wrap(),
      map.getZoom(),
      map.getLayersCode(),
      map._object);

    Cookies.set("_osm_location", OSM.locationCookie(map), { secure: true, expires: expiry, path: "/", samesite: "lax" });
  });

  if (Cookies.get("_osm_welcome") !== "hide") {
    $(".welcome").removeAttr("hidden");
  }

  $(".welcome .btn-close").on("click", function () {
    $(".welcome").hide();
    Cookies.set("_osm_welcome", "hide", { secure: true, expires: expiry, path: "/", samesite: "lax" });
  });

  const bannerExpiry = new Date();
  bannerExpiry.setYear(bannerExpiry.getFullYear() + 1);

  $("#banner .btn-close").on("click", function (e) {
    const cookieId = e.target.id;
    $("#banner").hide();
    e.preventDefault();
    if (cookieId) {
      Cookies.set(cookieId, "hide", { secure: true, expires: bannerExpiry, path: "/", samesite: "lax" });
    }
  });

  if (OSM.MATOMO) {
    map.on("baselayerchange overlayadd", function (e) {
      if (e.layer.options) {
        const goal = OSM.MATOMO.goals[e.layer.options.layerId];

        if (goal) {
          $("body").trigger("matomogoal", goal);
        }
      }
    });
  }

  if (params.bounds) {
    map.fitBounds(params.bounds);
  } else {
    map.setView([params.lat, params.lon], params.zoom);
  }

  if (params.marker) {
    L.marker([params.mlat, params.mlon]).addTo(map);
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
        // eslint-disable-next-line no-alert
        alert(OSM.i18n.t("site.index.remote_failed"));
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

  OSM.Index = function (map) {
    const page = {};

    page.pushstate = page.popstate = function () {
      map.setSidebarOverlaid(true);
      document.title = OSM.i18n.t("layouts.project_name.title");
    };

    page.load = function () {
      const params = new URLSearchParams(location.search);
      if (params.has("query")) {
        $("#sidebar .search_form input[name=query]").value(params.get("query"));
      }
      if (!("autofocus" in document.createElement("input"))) {
        $("#sidebar .search_form input[name=query]").focus();
      }
      return map.getState();
    };

    return page;
  };

  OSM.Browse = function (map, type) {
    const page = {};

    page.pushstate = page.popstate = function (path, id, version) {
      OSM.loadSidebarContent(path, function () {
        addObject(type, id, version);
      });
    };

    page.load = function (path, id, version) {
      addObject(type, id, version, true);
    };

    function addObject(type, id, version, center) {
      const hashParams = OSM.parseHash();
      map.addObject({ type: type, id: parseInt(id, 10), version: version && parseInt(version, 10) }, function (bounds) {
        if (!hashParams.center && bounds.isValid() &&
            (center || !map.getBounds().contains(bounds))) {
          OSM.router.withoutMoveListener(function () {
            map.fitBounds(bounds);
          });
        }
      });
    }

    page.unload = function () {
      map.removeObject();
    };

    return page;
  };

  OSM.OldBrowse = function () {
    const page = {};

    page.pushstate = page.popstate = function (path) {
      OSM.loadSidebarContent(path);
    };

    return page;
  };

  const history = OSM.History(map);

  OSM.router = OSM.Router(map, {
    "/": OSM.Index(map),
    "/search": OSM.Search(map),
    "/directions": OSM.Directions(map),
    "/export": OSM.Export(map),
    "/note/new": OSM.NewNote(map),
    "/history/friends": history,
    "/history/nearby": history,
    "/history": history,
    "/user/:display_name/history": history,
    "/note/:id": OSM.Note(map),
    "/node/:id(/history)": OSM.Browse(map, "node"),
    "/node/:id/history/:version": OSM.Browse(map, "node"),
    "/way/:id(/history)": OSM.Browse(map, "way"),
    "/way/:id/history/:version": OSM.OldBrowse(),
    "/relation/:id(/history)": OSM.Browse(map, "relation"),
    "/relation/:id/history/:version": OSM.OldBrowse(),
    "/changeset/:id": OSM.Changeset(map),
    "/query": OSM.Query(map),
    "/account/home": OSM.Home(map)
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
    if (location.protocol !== this.protocol || location.host !== this.host) {
      return;
    }

    if (OSM.router.route(this.pathname + this.search + this.hash)) {
      e.preventDefault();
      if (this.pathname !== "/directions") {
        $("header").addClass("closed");
      }
    }
  });

  $(document).on("click", "#sidebar .sidebar-close-controls button", function () {
    OSM.router.route("/" + OSM.formatHash(map));
  });
});
