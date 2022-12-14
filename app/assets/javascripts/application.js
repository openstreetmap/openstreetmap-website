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
//= require leaflet.locationfilter
//= require i18n
//= require oauth
//= require matomo
//= require richtext
//= require qs/dist/qs
//= require bs-custom-file-input
//= require bs-custom-file-input-init

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

window.maximiseMap = function () {
  $("#content").addClass("maximised");
};

window.minimiseMap = function () {
  $("#content").removeClass("maximised");
};

$(document).ready(function () {
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

    updateHeader();

    $(window).resize(updateHeader);
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
