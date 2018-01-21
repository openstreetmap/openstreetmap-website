//= require jquery3
//= require jquery_ujs
//= require jquery.timers
//= require jquery.cookie
//= require jquery.throttle-debounce
//= require bootstrap.tooltip
//= require bootstrap.dropdown
//= require augment
//= require osm
//= require leaflet
//= require leaflet.osm
//= require leaflet.map
//= require leaflet.zoom
//= require leaflet.locationfilter
//= require i18n/translations
//= require oauth
//= require piwik
//= require richtext
//= require querystring

var querystring = require('querystring-component');

/*
 * Called as the user scrolls/zooms around to maniplate hrefs of the
 * view tab and various other links
 */
window.updateLinks = function (loc, zoom, layers, object) {
  $(".geolink").each(function(index, link) {
    var href = link.href.split(/[?#]/)[0],
      args = querystring.parse(link.search.substring(1)),
      editlink = $(link).hasClass("editlink");

    delete args.node;
    delete args.way;
    delete args.relation;
    delete args.changeset;

    if (object && editlink) {
      args[object.type] = object.id;
    }

    var query = querystring.stringify(args);
    if (query) href += '?' + query;

    args = {
      lat: loc.lat,
      lon: 'lon' in loc ? loc.lon : loc.lng,
      zoom: zoom
    };

    if (layers && !editlink) {
      args.layers = layers;
    }

    href += OSM.formatHash(args);

    link.href = href;
  });

  var editDisabled = zoom < 13;
  $('#edit_tab')
    .tooltip({placement: 'bottom'})
    .off('click.minzoom')
    .on('click.minzoom', function() { return !editDisabled; })
    .toggleClass('disabled', editDisabled)
    .attr('data-original-title', editDisabled ?
      I18n.t('javascripts.site.edit_disabled_tooltip') : '');
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
      $("body").removeClass("compact").addClass("small");
    } else if (windowWidth < headerWidth) {
      $("body").addClass("compact").removeClass("small");
    } else {
      $("body").removeClass("compact").removeClass("small");
    }
  }

  /*
   * Chrome 60 and later seem to fire the "ready" callback
   * before the DOM is fully ready causing us to measure the
   * wrong sizes for the header elements - use a 0ms timeout
   * to defer the measurement slightly as a workaround.
   */
  setTimeout(function () {
    $("header").children(":visible").each(function (i,e) {
      headerWidth = headerWidth + $(e).outerWidth();
    });

    $("body").addClass("compact");

    $("header").children(":visible").each(function (i,e) {
      compactWidth = compactWidth + $(e).outerWidth();
    });

    $("body").removeClass("compact");

    updateHeader();

    $(window).resize(updateHeader);
  }, 0);

  $("#menu-icon").on("click", function(e) {
    e.preventDefault();
    $("header").toggleClass("closed");
  });

  $("nav.primary li a").on("click", function() {
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
});
