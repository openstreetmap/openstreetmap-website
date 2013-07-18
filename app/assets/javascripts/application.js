//= require jquery
//= require jquery_ujs
//= require jquery.timers
//= require jquery.cookie
//= require augment
//= require leaflet
//= require leaflet.osm
//= require leaflet.zoom
//= require leaflet.extend
//= require leaflet.locationfilter
//= require i18n/translations
//= require oauth
//= require osm
//= require piwik
//= require map
//= require menu
//= require sidebar
//= require richtext
//= require geocoder
//= require querystring

var querystring = require('querystring-component');

function zoomPrecision(zoom) {
    var decimals = Math.pow(10, Math.floor(zoom/3));
    return function(x) {
         return Math.round(x * decimals) / decimals;
    };
}

function normalBounds(bounds) {
    if (bounds instanceof L.LatLngBounds) return bounds;
    return new L.LatLngBounds(
        new L.LatLng(bounds[0][0], bounds[0][1]),
        new L.LatLng(bounds[1][0], bounds[1][1]));
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
  $("#linkloader")
    .attr("src", "http://127.0.0.1:8111/load_and_zoom?" + querystring.stringify(query))
    .load(function() { loaded = true; });

  setTimeout(function () {
    if (!loaded) alert(I18n.t('site.index.remote_failed'));
  }, 1000);

  return false;
}

/*
 * Called as the user scrolls/zooms around to maniplate hrefs of the
 * view tab and various other links
 */
function updatelinks(loc, zoom, layers, bounds, object) {
  var toPrecision = zoomPrecision(zoom);
  bounds = normalBounds(bounds);
  var node;

  var lat = toPrecision(loc.lat),
      lon = toPrecision(loc.lon || loc.lng);

  if (bounds) {
    var minlon = toPrecision(bounds.getWest()),
        minlat = toPrecision(bounds.getSouth()),
        maxlon = toPrecision(bounds.getEast()),
        maxlat = toPrecision(bounds.getNorth());
  }

  $(".geolink").each(setGeolink);

  function setGeolink(index, link) {
    var base = link.href.split('?')[0],
        qs = link.href.split('?')[1],
        args = querystring.parse(qs);

    if ($(link).hasClass("llz")) {
      $.extend(args, {
          lat: lat,
          lon: lon,
          zoom: zoom
      });
    } else if (minlon && $(link).hasClass("bbox")) {
      $.extend(args, {
          bbox: minlon + "," + minlat + "," + maxlon + "," + maxlat
      });
    }

    if (layers && $(link).hasClass("layers")) args.layers = layers;
    if (object && $(link).hasClass("object")) args[object.type] = object.id;

    var minzoom = $(link).data("minzoom");
    if (minzoom) {
      var name = link.id.replace(/anchor$/, "");
      $(link).off("click.minzoom");
      if (zoom >= minzoom) {
        $(link)
          .attr("title", I18n.t("javascripts.site." + name + "_tooltip"))
          .removeClass("disabled");
      } else {
        $(link)
          .attr("title", I18n.t("javascripts.site." + name + "_disabled_tooltip"))
          .addClass("disabled")
          .on("click.minzoom", function () {
            alert(I18n.t("javascripts.site." + name + "_zoom_alert"));
            return false;
          });
      }
    }
    link.href = base + '?' + querystring.stringify(args);
  }
}

function getShortUrl(map) {
  return (window.location.hostname.match(/^www\.openstreetmap\.org/i) ?
          'http://osm.org/go/' : 'http://' + window.location.hostname + '/go/') +
          makeShortCode(map);
}

function getUrl(map) {
  var center = map.getCenter(),
      zoom = map.getZoom(),
      toZoom = zoomPrecision(zoom);

  return (window.location.hostname.match(/^www\.openstreetmap\.org/i) ?
          'http://openstreetmap.org/?' : 'http://' + window.location.hostname + '/?') +
        querystring.stringify({
            lat: toZoom(center.lat),
            lon: toZoom(center.lng),
            zoom: zoom,
            layers: map.getLayersCode()
        });
}

// Called to create a short code for the short link.
function makeShortCode(map) {
    var zoom = map.getZoom(),
        str = '',
        char_array = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_~",
        x = Math.round((map.getCenter().lng + 180.0) * ((1 << 30) / 90.0)),
        y = Math.round((map.getCenter().lat +  90.0) * ((1 << 30) / 45.0)),
        // JavaScript only has to keep 32 bits of bitwise operators, so this has to be
        // done in two parts. each of the parts c1/c2 has 30 bits of the total in it
        // and drops the last 4 bits of the full 64 bit Morton code.
        c1 = interlace(x >>> 17, y >>> 17), c2 = interlace((x >>> 2) & 0x7fff, (y >>> 2) & 0x7fff);

    for (var i = 0; i < Math.ceil((zoom + 8) / 3.0) && i < 5; ++i) {
        digit = (c1 >> (24 - 6 * i)) & 0x3f;
        str += char_array.charAt(digit);
    }
    for (i = 5; i < Math.ceil((zoom + 8) / 3.0); ++i) {
        digit = (c2 >> (24 - 6 * (i - 5))) & 0x3f;
        str += char_array.charAt(digit);
    }
    for (i = 0; i < ((zoom + 8) % 3); ++i) str += "-";

    // Called to interlace the bits in x and y, making a Morton code.
    function interlace(x, y) {
        x = (x | (x << 8)) & 0x00ff00ff;
        x = (x | (x << 4)) & 0x0f0f0f0f;
        x = (x | (x << 2)) & 0x33333333;
        x = (x | (x << 1)) & 0x55555555;
        y = (y | (y << 8)) & 0x00ff00ff;
        y = (y | (y << 4)) & 0x0f0f0f0f;
        y = (y | (y << 2)) & 0x33333333;
        y = (y | (y << 1)) & 0x55555555;
        return (x << 1) | y;
    }

    return str;
}

// generate a cookie-safe string of map state
function cookieContent(map) {
  var center = map.getCenter().wrap();
  return [center.lng, center.lat, map.getZoom(), map.getLayersCode()].join('|');
}

/*
 * Forms which have been cached by rails may have the wrong
 * authenticity token, so patch up any forms with the correct
 * token taken from the page header.
 */
$(document).ready(function () {
  var auth_token = $("meta[name=csrf-token]").attr("content");
  $("form input[name=authenticity_token]").val(auth_token);
});
