//= require_self
//= require leaflet.sidebar
//= require leaflet.sidebar-pane
//= require leaflet.locatecontrol/src/L.Control.Locate
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
//= require index/browse
//= require index/export
//= require index/notes
//= require index/history
//= require index/note
//= require index/new_note
//= require index/directions
//= require index/changeset
//= require index/query
//= require index/timeslider
//= require router
//= require qs/dist/qs

$(document).ready(function () {
  var loaderTimeout;

  var map = new L.OSM.Map("map", {
    zoomControl: false,
    layerControl: false,
    contextmenu: true,
    minZoom: 2,  /* match to "L.MaplibreGL" options in leaflet.map.js */
    maxZoom: 20,  /* match to "L.MaplibreGL" options in leaflet.map.js */
    maxBounds: [[-90, -180], [90, 180]],  /* prevents vector & raster maps from slipping out of sync at extreme latitudes */    worldCopyJump: true
  });

  OSM.loadSidebarContent = function (path, callback) {
    var content_path = path;

    map.setSidebarOverlaid(false);

    clearTimeout(loaderTimeout);

    loaderTimeout = setTimeout(function () {
      $("#sidebar_loader").show();
    }, 200);

    // IE<10 doesn't respect Vary: X-Requested-With header, so
    // prevent caching the XHR response as a full-page URL.
    if (content_path.indexOf("?") >= 0) {
      content_path += "&xhr=1";
    } else {
      content_path += "?xhr=1";
    }

    $("#sidebar_content")
      .empty();

    $.ajax({
      url: content_path,
      dataType: "html",
      complete: function (xhr) {
        clearTimeout(loaderTimeout);
        $("#flash").empty();
        $("#sidebar_loader").hide();

        var content = $(xhr.responseText);

        if (xhr.getResponseHeader("X-Page-Title")) {
          var title = xhr.getResponseHeader("X-Page-Title");
          document.title = decodeURIComponent(title);
        }

        $("head")
          .find("link[type=\"application/atom+xml\"]")
          .remove();

        $("head")
          .append(content.filter("link[type=\"application/atom+xml\"]"));

        $("#sidebar_content").html(content.not("link[type=\"application/atom+xml\"]"));

        if (callback) {
          callback();
        }
      }
    });
  };

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
    controls.forEach(function (control) {
      control.addTo(map);
    });

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
    OSM.initializeNotes(map);
    if (params.layers.indexOf(map.noteLayer.options.code) >= 0) {
      map.addLayer(map.noteLayer);
    }

    OSM.initializeBrowse(map);
    if (params.layers.indexOf(map.dataLayer.options.code) >= 0) {
      map.addLayer(map.dataLayer);
    }

    if (params.layers.indexOf(map.gpsLayer.options.code) >= 0) {
      map.addLayer(map.gpsLayer);
    }
  }

  var placement = $("html").attr("dir") === "rtl" ? "right" : "left";
  $(".leaflet-control .control-button").tooltip({ placement: placement, container: "body" });

  var expiry = new Date();
  expiry.setYear(expiry.getFullYear() + 10);

  map.on("moveend layeradd layerremove", function () {
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
    map.on("layeradd", function (e) {
      if (e.layer.options) {
        var goal = OSM.MATOMO.goals[e.layer.options.keyid];

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
        query = {
          left: bbox.getWest() - 0.0001,
          top: bbox.getNorth() + 0.0001,
          right: bbox.getEast() + 0.0001,
          bottom: bbox.getSouth() - 0.0001
        };

    if (object && object.type !== "note") query.select = object.type + object.id; // can't select notes
    sendRemoteEditCommand(remoteEditHost + "/load_and_zoom?" + Qs.stringify(query), function () {
      if (object && object.type === "note") {
        var noteQuery = { url: osmHost + OSM.apiUrl(object) };
        sendRemoteEditCommand(remoteEditHost + "/import?" + Qs.stringify(noteQuery));
      }
    });

    function sendRemoteEditCommand(url, callback) {
      var iframe = $("<iframe>");
      var timeoutId = setTimeout(function () {
        alert(I18n.t("site.index.remote_failed"));
        iframe.remove();
      }, 5000);

      iframe
        .hide()
        .appendTo("body")
        .attr("src", url)
        .on("load", function () {
          clearTimeout(timeoutId);
          iframe.remove();
          if (callback) callback();
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

    page.load = function() {
      // the original page.load content is the function below, and is used when one visits this page, be it first load OR later routing change
      // below, we wrap "if map.timeslider" so we only try to add the timeslider if we don't already have it
      function originalLoadFunction () {
      var params = querystring.parse(location.search.substring(1));      if (params.query) {
        $("#sidebar .search_form input[name=query]").value(params.query);
      }
      if (!("autofocus" in document.createElement("input"))) {
        $("#sidebar .search_form input[name=query]").focus();
      }
      return map.getState();
      }  // end originalLoadFunction

      // "if map.timeslider" only try to add the timeslider if we don't already have it
      if (map.timeslider) {
        originalLoadFunction();
      }
      else {
        var params = querystring.parse(location.hash ? location.hash.substring(1) : location.search.substring(1));
        addOpenHistoricalMapTimeSlider(map, params, originalLoadFunction);
      }
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

    // page.load was originally simply the addObject() call
    // but with MBGLTimeSlider we need to wait for it to become ready
    page.load = function(path, id) {
      // the original page.load content is the function below, and is used when one visits this page, be it first load OR later routing change
      // below, we wrap "if map.timeslider" so we only try to add the timeslider if we don't already have it
      function originalLoadFunction () {
      addObject(type, id, true);
      }  // end originalLoadFunction

      // "if map.timeslider" only try to add the timeslider if we don't already have it
      if (map.timeslider) {
        originalLoadFunction();
      }
      else {
        var params = querystring.parse(location.hash ? location.hash.substring(1) : location.search.substring(1));
        addOpenHistoricalMapTimeSlider(map, params, originalLoadFunction);
      }
    };

    function addObject(type, id, center) {
      // cache these now, before the URL param updating starts and messes it up
      var hasurlparam_center = window.location.hash.indexOf('map=') !== -1;
      var hasurlparam_daterange = window.location.hash.indexOf('daterange=') !== -1;

      map.addObject({type: type, id: parseInt(id)}, function(bounds) {
        const zoomtoit = bounds.isValid() && (center || ! hasurlparam_center);
        if (zoomtoit) {
          OSM.router.withoutMoveListener(function () {
            map.fitBounds(bounds);
          });
        }

        var drawing = map._objectLayer.getLayers()[0];
        if (drawing && ! hasurlparam_daterange) {
          var startdate = drawing.feature.tags.start_date && ! isNaN(parseInt(drawing.feature.tags.start_date)) ? drawing.feature.tags.start_date : undefined;
          var enddate = drawing.feature.tags.end_date && ! isNaN(parseInt(drawing.feature.tags.end_date)) ? drawing.feature.tags.end_date : undefined;

          if (startdate && enddate) {
            map.timeslider.setDate(startdate).setRange([startdate, enddate]);
          }
          else if (startdate) {
            map.timeslider.setDate(startdate).setRangeLower(startdate);
          }
          else if (enddate) {
            map.timeslider.setDate(enddate).setRangeUpper(enddate);
          }
        }
      });

      setTimeout(addOpenHistoricalMapInspector(), 250);

      $(".colour-preview-box").each(function () {
        $(this).css("background-color", $(this).data("colour"));
      });
    }

    page.unload = function () {
      map.removeObject();
    };

    return page;
  };

  // add the enhanced inspector
  function addOpenHistoricalMapInspector () {
    var inspector = new openhistoricalmap.OpenHistoricaMapInspector({
        debug: true,
        onFeatureFail: function (type, id) {
            console.log([ 'failed to load feature', type, id ]);
        },
        onFeatureLoaded: function (type, id, xmldoc) {
            console.log([ 'loaded feature', type, id, xmldoc ]);
        },
        apiBaseUrl: "/api",  // no trailing /
    });
    inspector.selectFeatureFromUrl();
  }

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
    "/way/:id(/history)": OSM.Browse(map, "way"),
    "/relation/:id(/history)": OSM.Browse(map, "relation"),
    "/changeset/:id": OSM.Changeset(map),
    "/query": OSM.Query(map)
  });

  if (OSM.preferred_editor === "remote" && document.location.pathname === "/edit") {
    remoteEditHandler(map.getBounds(), params.object);
    OSM.router.setCurrentPath("/");
  }

  OSM.router.load();

  $(document).on("click", "a", function (e) {
    if (e.isDefaultPrevented() || e.isPropagationStopped()) {
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
    }
  });

  $(document).on("click", "#sidebar_content .btn-close", function () {
    OSM.router.route("/" + OSM.formatHash(map));
  });
});
