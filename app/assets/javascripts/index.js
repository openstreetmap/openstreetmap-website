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
//= require router

$(document).ready(function () {
  var map = new L.OSM.Map("map", {
    zoomControl: false,
    layerControl: false,
    contextmenu: true,
    worldCopyJump: true
  });

  OSM.loadSidebarContent = function (path, callback) {
    var content_path = path;

    map.setSidebarOverlaid(false);

    $("#sidebar_loader").show().addClass("delayed-fade-in");

    $("#sidebar_content")
      .empty();

    fetch(content_path, { headers: { "accept": "text/html", "x-requested-with": "XMLHttpRequest" } })
      .then(response => {
        $("#flash").empty();
        $("#sidebar_loader").removeClass("delayed-fade-in").hide();

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
  $(document).ready(function(){
    $('#sidebar').on('mousedown', function(e){
        var $dragable = $(this),
            startWidth = $dragable.width(),
            pX = e.pageX;
        
        $(document).on('mouseup', function(e){
            $(document).off('mouseup').off('mousemove');
        });
        $(document).on('mousemove', function(me){
            var mx = (me.pageX - pX);
            //var my = (me.pageY - pY);
            
            $dragable.css({
                width: startWidth + mx,
                //top: my
            });
        });
                
    });
   });
  var params = OSM.mapParams();

  map.attributionControl.setPrefix("");

  map.updateLayers(params.layers);

  map.on("baselayerchange", function (e) {
    if (map.getZoom() > e.layer.options.maxZoom) {
      map.setView(map.getCenter(), e.layer.options.maxZoom, { reset: true });
    }
  });

  var sidebar = L.OSM.sidebar("#map-ui")
    .addTo(map);

  var position = $("html").attr("dir") === "rtl" ? "topleft" : "topright";

  function addControlGroup(controls) {
    for (const control of controls) control.addTo(map);

    var firstContainer = controls[0].getContainer();
    $(firstContainer).find(".control-button").first()
      .addClass("control-button-first");

    var lastContainer = controls[controls.length - 1].getContainer();
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

  var expiry = new Date();
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

  var bannerExpiry = new Date();
  bannerExpiry.setYear(bannerExpiry.getFullYear() + 1);

  $("#banner .btn-close").on("click", function (e) {
    var cookieId = e.target.id;
    $("#banner").hide();
    e.preventDefault();
    if (cookieId) {
      Cookies.set(cookieId, "hide", { secure: true, expires: bannerExpiry, path: "/", samesite: "lax" });
    }
  });

  if (OSM.MATOMO) {
    map.on("baselayerchange overlayadd", function (e) {
      if (e.layer.options) {
        var goal = OSM.MATOMO.goals[e.layer.options.layerId];

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

  $("#homeanchor").on("click", function (e) {
    e.preventDefault();

    var data = $(this).data(),
        center = L.latLng(data.lat, data.lon);

    map.setView(center, data.zoom);
    L.marker(center, { icon: OSM.getUserIcon() }).addTo(map);
  });

  function remoteEditHandler(bbox, object) {
    var remoteEditHost = "http://127.0.0.1:8111",
        osmHost = location.protocol + "//" + location.host,
        query = new URLSearchParams({
          left: bbox.getWest() - 0.0001,
          top: bbox.getNorth() + 0.0001,
          right: bbox.getEast() + 0.0001,
          bottom: bbox.getSouth() - 0.0001
        });

    if (object && object.type !== "note") query.set("select", object.type + object.id); // can't select notes
    sendRemoteEditCommand(remoteEditHost + "/load_and_zoom?" + query, function () {
      if (object && object.type === "note") {
        const noteQuery = new URLSearchParams({ url: osmHost + OSM.apiUrl(object) });
        sendRemoteEditCommand(remoteEditHost + "/import?" + noteQuery);
      }
    });

    function sendRemoteEditCommand(url, callback) {
      fetch(url, { mode: "no-cors", signal: AbortSignal.timeout(5000) })
        .then(callback)
        .catch(function () {
          // eslint-disable-next-line no-alert
          alert(I18n.t("site.index.remote_failed"));
        });
    }

    return false;
  }

  $("a[data-editor=remote]").click(function (e) {
    var params = OSM.mapParams(this.search);
    remoteEditHandler(map.getBounds(), params.object);
    e.preventDefault();
  });

  if (OSM.params().edit_help) {
    $("#editanchor")
      .removeAttr("title")
      .tooltip({
        placement: "bottom",
        title: I18n.t("javascripts.edit_help")
      })
      .tooltip("show");

    $("body").one("click", function () {
      $("#editanchor").tooltip("hide");
    });
  }

  OSM.Index = function (map) {
    var page = {};

    page.pushstate = page.popstate = function () {
      map.setSidebarOverlaid(true);
      document.title = I18n.t("layouts.project_name.title");
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
    var page = {};

    page.pushstate = page.popstate = function (path, id) {
      OSM.loadSidebarContent(path, function () {
        addObject(type, id);
      });
    };

    page.load = function (path, id) {
      addObject(type, id, true);
    };

    function addObject(type, id, center) {
      var hashParams = OSM.parseHash(window.location.hash);
      map.addObject({ type: type, id: parseInt(id, 10) }, function (bounds) {
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
    var page = {};

    page.pushstate = page.popstate = function (path) {
      OSM.loadSidebarContent(path);
    };

    return page;
  };

  var history = OSM.History(map);

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
    "/node/:id/history/:version": OSM.OldBrowse(),
    "/way/:id(/history)": OSM.Browse(map, "way"),
    "/way/:id/history/:version": OSM.OldBrowse(),
    "/relation/:id(/history)": OSM.Browse(map, "relation"),
    "/relation/:id/history/:version": OSM.OldBrowse(),
    "/changeset/:id": OSM.Changeset(map),
    "/query": OSM.Query(map)
  });

  if (OSM.preferred_editor === "remote" && document.location.pathname === "/edit") {
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

  $(document).on("click", "#sidebar_content .btn-close", function () {
    OSM.router.route("/" + OSM.formatHash(map));
  });
});
