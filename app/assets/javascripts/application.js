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
//= require leaflet.hash
//= require leaflet.zoom
//= require leaflet.extend
//= require leaflet.locationfilter
//= require i18n/translations
//= require oauth
//= require piwik
//= require map
//= require richtext
//= require querystring

var querystring = require('querystring-component');

function zoomPrecision(zoom) {
    return Math.max(0, Math.ceil(Math.log(zoom) / Math.LN2));
}

function remoteEditHandler(bbox, select) {
  var loaded = false,
      query = {
          left: bbox.getWest() - 0.0001,
          top: bbox.getNorth() + 0.0001,
          right: bbox.getEast() + 0.0001,
          bottom: bbox.getSouth() - 0.0001
      };

  if (select) query.select = select;

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
function updatelinks(loc, zoom, layers, object) {
  $(".geolink").each(function(index, link) {
    var href = link.href.split(/[?#]/)[0],
        args = querystring.parse(link.search.substring(1));

    if (object && $(link).hasClass("object")) args[object.type] = object.id;

    var query = querystring.stringify(args);
    if (query) href += '?' + query;

    args = {
      lat: loc.lat,
      lon: loc.lon || loc.lng,
      zoom: zoom
    };

    if (layers && $(link).hasClass("layers")) {
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

/*
 * Forms which have been cached by rails may have the wrong
 * authenticity token, so patch up any forms with the correct
 * token taken from the page header.
 */
$(document).ready(function () {
  var auth_token = $("meta[name=csrf-token]").attr("content");
  $("form input[name=authenticity_token]").val(auth_token);

  $("#menu-icon").on("click", function() {
    $("header").toggleClass("closed");
  });
});
