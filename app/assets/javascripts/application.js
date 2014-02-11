//= require jquery
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

function zoomPrecision(zoom) {
    return Math.max(0, Math.ceil(Math.log(zoom) / Math.LN2));
}

function remoteEditHandler(bbox, object) {
  var loaded = false,
      query = {
          left: bbox.getWest() - 0.0001,
          top: bbox.getNorth() + 0.0001,
          right: bbox.getEast() + 0.0001,
          bottom: bbox.getSouth() - 0.0001
      };

  if (object) query.select = object.type + object.id;

  var iframe = $('<iframe>')
    .hide()
    .appendTo('body')
    .attr("src", "http://127.0.0.1:8111/load_and_zoom?" + querystring.stringify(query))
    .on('load', function() {
      $(this).remove();
      loaded = true;
    });

  setTimeout(function () {
    if (!loaded) {
      alert(I18n.t('site.index.remote_failed'));
      iframe.remove();
    }
  }, 1000);

  return false;
}

/*
 * Called as the user scrolls/zooms around to maniplate hrefs of the
 * view tab and various other links
 */
function updateLinks(loc, zoom, layers, object) {
  $(".geolink").each(function(index, link) {
    var href = link.href.split(/[?#]/)[0],
      args = querystring.parse(link.search.substring(1)),
      editlink = $(link).hasClass("editlink");

    delete args['node'];
    delete args['way'];
    delete args['relation'];
    delete args['changeset'];

    if (object && editlink) {
      args[object.type] = object.id;
    }

    var query = querystring.stringify(args);
    if (query) href += '?' + query;

    args = {
      lat: loc.lat,
      lon: loc.lon || loc.lng,
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
}

// generate a cookie-safe string of map state
function cookieContent(map) {
  var center = map.getCenter().wrap();
  return [center.lng, center.lat, map.getZoom(), map.getLayersCode()].join('|');
}

function escapeHTML(string) {
  var htmlEscapes = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#x27;'
  };
  return string == null ? '' : (string + '').replace(/[&<>"']/g, function(match) {
      return htmlEscapes[match];
  });
}

function maximiseMap() {
  $("#content").addClass("maximised");
}

function minimiseMap() {
  $("#content").removeClass("maximised");
}

$(document).ready(function () {
  $("#menu-icon").on("click", function(e) {
    e.preventDefault();
    $("header").toggleClass("closed");
  });

  $("nav.primary li a").on("click", function() {
    $("header").toggleClass("closed");
  });
});
