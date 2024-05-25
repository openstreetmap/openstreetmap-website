//= require jquery3
//= require jquery_ujs
//= require jquery.timers
//= require jquery.throttle-debounce
//= require js-cookie/dist/js.cookie
//= require popper
//= require bootstrap-sprockets
//= require osm
//= require leaflet/dist/leaflet-src
//= require leaflet.osm
//= require leaflet.map
//= require leaflet.zoom
//= require leaflet.locatecontrol/src/L.Control.Locate
//= require leaflet.locationfilter
//= require i18n
//= require oauth
//= require matomo
//= require richtext
//= require qs/dist/qs

/*
 * Called as the user scrolls/zooms around to manipulate hrefs of the
 * view tab and various other links
 */
window.updateLinks = function (loc, zoom, layers, object) {
  $(".geolink").each(function (index, link) {
    var href = link.href.split(/[?#]/)[0],
        args = Qs.parse(link.search.substring(1)),
        editlink = $(link).hasClass("editlink");

    delete args.node;
    delete args.way;
    delete args.relation;
    delete args.changeset;
    delete args.note;

    if (object && editlink) {
      args[object.type] = object.id;
    }

    var query = Qs.stringify(args);
    if (query) href += "?" + query;

    args = {
      lat: loc.lat,
      lon: "lon" in loc ? loc.lon : loc.lng,
      zoom: zoom
    };

    if (layers && !editlink) {
      args.layers = layers;
    }

    href += OSM.formatHash(args);

    link.href = href;
  });

  // Disable the button group and also the buttons to avoid
  // inconsistent behaviour when zooming
  var editDisabled = zoom < 13;
  $("#edit_tab")
    .tooltip({ placement: "bottom" })
    .tooltip(editDisabled ? "enable" : "disable")
    .toggleClass("disabled", editDisabled)
    .find("a")
    .toggleClass("disabled", editDisabled);
};

$(document).ready(function () {
  // NB: Turns Turbo Drive off by default. Turbo Drive must be opt-in on a per-link and per-form basis
  // See https://turbo.hotwired.dev/reference/drive#turbo.session.drive
  Turbo.session.drive = false;

  var headerWidth = 0,
      compactWidth = 0;

  function updateHeader() {
    var windowWidth = $(window).width();

    if (windowWidth < compactWidth) {
      $("body").removeClass("compact-nav").addClass("small-nav");
    } else if (windowWidth < headerWidth) {
      $("body").addClass("compact-nav").removeClass("small-nav");
    } else {
      $("body").removeClass("compact-nav").removeClass("small-nav");
    }
  }

  /*
   * Chrome 60 and later seem to fire the "ready" callback
   * before the DOM is fully ready causing us to measure the
   * wrong sizes for the header elements - use a 0ms timeout
   * to defer the measurement slightly as a workaround.
   */
  setTimeout(function () {
    $("header").children(":visible").each(function (i, e) {
      headerWidth = headerWidth + $(e).outerWidth();
    });

    $("body").addClass("compact-nav");

    $("header").children(":visible").each(function (i, e) {
      compactWidth = compactWidth + $(e).outerWidth();
    });

    $("body").removeClass("compact-nav");

    $("header").removeClass("text-nowrap");
    $("header nav.secondary > ul").removeClass("flex-nowrap");

    updateHeader();

    $(window).resize(updateHeader);
    $(document).on("turbo:render", updateHeader);
  }, 0);

  $("#menu-icon").on("click", function (e) {
    e.preventDefault();
    $("header").toggleClass("closed");
  });

  $("nav.primary li a").on("click", function () {
    $("header").toggleClass("closed");
  });

  var application_data = $("head").data();

  I18n.default_locale = OSM.DEFAULT_LOCALE;
  I18n.locale = application_data.locale;
  I18n.fallbacks = true;

  OSM.preferred_editor = application_data.preferredEditor;
  OSM.preferred_languages = application_data.preferredLanguages;

  if (application_data.user) {
    OSM.user = application_data.user;

    if (application_data.userHome) {
      OSM.home = application_data.userHome;
    }
  }

  if (application_data.location) {
    OSM.location = application_data.location;
  }

  $("#edit_tab")
    .attr("title", I18n.t("javascripts.site.edit_disabled_tooltip"));
});

window.addLocateControl = function (map, position) {
  var locate = L.control.locate({
    position: position,
    icon: "icon geolocate",
    iconLoading: "icon geolocate",
    strings: {
      title: I18n.t("javascripts.map.locate.title"),
      popup: function (options) {
        return I18n.t("javascripts.map.locate." + options.unit + "Popup", { count: options.distance });
      }
    }
  }).addTo(map);
  $(locate.getContainer())
    .removeClass("leaflet-control-locate leaflet-bar")
    .addClass("control-locate")
    .children("a")
    .attr("href", "#")
    .removeClass("leaflet-bar-part leaflet-bar-part-single")
    .addClass("control-button");
};

/*
 * Create a map on the page for the given `id`.  Adhere to rtl pages.  Parameters to
 * the map are provided as data attributes.
 *    * zoom
 *    * latitude, longitude
 *    * min-lat, max-lat, min-lon, max-lon
 * If the map div has a class `has_marker` there will be a marker added to the map.
 */
window.showMap = function (id) {
  const div = $("#" + id);
  // Defaults
  const position = $("html").attr("dir") === "rtl" ? "topleft" : "topright";
  let zoom = 2;
  let [latitude, longitude] = [0, 0];
  let bounds = null;
  let marker = null;

  // Extract params
  const params = div.data();
  if (params.zoom) {
    zoom = params.zoom;
  }
  if (params.latitude && params.longitude) {
    [latitude, longitude] = [params.latitude, params.longitude];
  }
  if (params.minLat && params.maxLat && params.minLon && params.maxLon) {
    bounds = [
      [params.minLat, params.minLon],
      [params.maxLat, params.maxLon]
    ];
  }

  // Create map.
  const map = L.map(id, {
    attributionControl: false,
    center: [latitude, longitude],
    zoom: zoom,
    zoomControl: false
  });
  window.addLocateControl(map, position);
  L.OSM.zoom({ position: position }).addTo(map);
  map.addLayer(new L.OSM.Mapnik());
  if (bounds) {
    map.fitBounds(bounds);
  }

  if (div.hasClass("has_marker")) {
    marker = L.marker([latitude, longitude], {
      icon: OSM.getUserIcon(),
      keyboard: false,
      interactive: false
    }).addTo(map);
  }

  return { map, marker };
};

/*
 * Create a basic map using showMap above, and connect it to the form that
 * contains it.  If the map div has the set_location class, the map will
 * set values in appropriate fields if they exist as the user clicks and
 * moves the map.  These fields are:
 *   * field_latitude
 *   * field_longitude
 *   * field_min_lat
 *   * field_max_lat
 *   * field_min_lon
 *   * field_max_lon
 */
window.formMapInit = function (id) {
  const formDiv = $("#" + id);
  const mapDiv = $("#" + id + "_map");
  const { map, marker } = window.showMap(id + "_map");

  if (mapDiv.hasClass("set_location")) {
    if ($(".field_latitude", formDiv) && $(".field_longitude", formDiv)) {
      map.on("click", function (e) {
        const location = e.latlng.wrap();
        marker.setLatLng(location);
        // If the page has these elements, populate them.
        $(".field_latitude", formDiv).val(location.lat);
        $(".field_longitude", formDiv).val(location.lng);
      });
    }

    if ($(".field_min_lat", formDiv) && $(".field_max_lat", formDiv) &&
      $(".field_min_lon", formDiv) && $(".field_max_lon", formDiv)) {
      map.on("move", function () {
        var bounds = map.getBounds();
        $(".field_min_lat").val(bounds._southWest.lat);
        $(".field_max_lat").val(bounds._northEast.lat);
        $(".field_min_lon").val(bounds._southWest.lng);
        $(".field_max_lon").val(bounds._northEast.lng);
      });
    }
  }
};
