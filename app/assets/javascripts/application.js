//= require jquery
//= require jquery_ujs
//= require jquery.timers
//= require jquery.cookie
//= require augment
//= require leaflet
//= require leaflet.osm
//= require leaflet.locationfilter
//= require leaflet.locate
//= require leaflet.note
//= require i18n/translations
//= require oauth
//= require osm
//= require piwik
//= require map
//= require menu
//= require sidebar
//= require leaflet.share
//= require richtext
//= require resize
//= require geocoder

function zoomPrecision(zoom) {
    var decimals = Math.pow(10, Math.floor(zoom/3));
    return function(x) {
         return Math.round(x * decimals) / decimals;
    };
}

/*
 * Called as the user scrolls/zooms around to aniplate hrefs of the
 * view tab and various other links
 */
function updatelinks(loc, zoom, layers, minlon, minlat, maxlon, maxlat, object) {
  var toPrecision = zoomPrecision(zoom);
  var node;

  var lat = toPrecision(loc.lat),
      lon = toPrecision(loc.lon || loc.lng);

  if (minlon) {
    minlon = toPrecision(minlon);
    minlat = toPrecision(minlat);
    maxlon = toPrecision(maxlon);
    maxlat = toPrecision(maxlat);
  }

  $(".geolink").each(setGeolink);
  $("#shortlinkanchor").each(setShortlink);

  function setGeolink(index, link) {
    var args = getArgs(link.href);

    if ($(link).hasClass("llz")) {
      args.lat = lat;
      args.lon = lon;
      args.zoom = zoom;
    } else if (minlon && $(link).hasClass("bbox")) {
      args.bbox = minlon + "," + minlat + "," + maxlon + "," + maxlat;
    }

    if (layers && $(link).hasClass("layers")) {
      args.layers = layers;
    }

    if (object && $(link).hasClass("object")) {
      args[object.type] = object.id;
    }

    var minzoom = $(link).data("minzoom");
    if (minzoom) {
        var name = link.id.replace(/anchor$/, "");

        $(link).off("click.minzoom");

        if (zoom >= minzoom) {
          $(link).attr("title", I18n.t("javascripts.site." + name + "_tooltip"))
              .removeClass("disabled");
        } else {
          $(link).on("click.minzoom", minZoomAlert)
              .attr("title", I18n.t("javascripts.site." + name + "_disabled_tooltip"))
              .addClass("disabled");
        }
    }

    link.href = setArgs(link.href, args);
  }

  function minZoomAlert() {
      alert(I18n.t("javascripts.site." + name + "_zoom_alert")); return false;
  }

  function setShortlink() {
    var args = getArgs(this.href);
    var code = makeShortCode(lat, lon, zoom);
    var prefix = shortlinkPrefix();

    // Add ?{node,way,relation}=id to the arguments
    if (object) {
      args[object.type] = object.id;
    }

    // This is a hack to omit the default mapnik layer from the shortlink.
    if (layers && layers != "M") {
      args.layers = layers;
    }
    else {
      delete args.layers;
    }

    // Here we're assuming that all parameters but ?layers= and
    // ?{node,way,relation}= can be safely omitted from the shortlink
    // which encodes lat/lon/zoom. If new URL parameters are added to
    // the main slippy map this needs to be changed.
    if (args.layers || object) {
      this.href = setArgs(prefix + "/go/" + code, args);
    } else {
      this.href = prefix + "/go/" + code;
    }
  }
}

/*
 * Get the URL prefix to use for a short link
 */
function shortlinkPrefix() {
  if (window.location.hostname.match(/^www\.openstreetmap\.org/i)) {
    return "http://osm.org";
  } else {
    return "";
  }
}

/*
 * Called to get the arguments from a URL as a hash.
 */
function getArgs(url) {
  var args = {};
  var querystart = url.indexOf("?");

  if (querystart >= 0) {
     var querystring = url.substring(querystart + 1);
     var queryitems = querystring.split("&");

     for (var i = 0; i < queryitems.length; i++) {
        if (match = queryitems[i].match(/^(.*)=(.*)$/)) {
           args[unescape(match[1])] = unescape(match[2]);
        } else {
           args[unescape(queryitems[i])] = null;
        }
     }
  }

  return args;
}

/*
 * Called to set the arguments on a URL from the given hash.
 */
function setArgs(url, args) {
   var queryitems = [];

   for (arg in args) {
      if (args[arg] == null) {
         queryitems.push(escape(arg));
      } else {
         queryitems.push(escape(arg) + "=" + escape(args[arg]));
      }
   }

   return url.replace(/\?.*$/, "") + "?" + queryitems.join("&");
}

/*
 * Called to interlace the bits in x and y, making a Morton code.
 */
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

/*
 * Called to create a short code for the short link.
 */
function makeShortCode(lat, lon, zoom) {
    char_array = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_~";
    var x = Math.round((lon + 180.0) * ((1 << 30) / 90.0));
    var y = Math.round((lat +  90.0) * ((1 << 30) / 45.0));
    // JavaScript only has to keep 32 bits of bitwise operators, so this has to be
    // done in two parts. each of the parts c1/c2 has 30 bits of the total in it
    // and drops the last 4 bits of the full 64 bit Morton code.
    var str = "";
    var c1 = interlace(x >>> 17, y >>> 17), c2 = interlace((x >>> 2) & 0x7fff, (y >>> 2) & 0x7fff);
    for (var i = 0; i < Math.ceil((zoom + 8) / 3.0) && i < 5; ++i) {
        digit = (c1 >> (24 - 6 * i)) & 0x3f;
        str += char_array.charAt(digit);
    }
    for (var i = 5; i < Math.ceil((zoom + 8) / 3.0); ++i) {
        digit = (c2 >> (24 - 6 * (i - 5))) & 0x3f;
        str += char_array.charAt(digit);
    }
    for (var i = 0; i < ((zoom + 8) % 3); ++i) {
        str += "-";
    }
    return str;
}

/*
 * Forms which have been cached by rails may have he wrong
 * authenticity token, so patch up any forms with the correct
 * token taken from the page header.
 */
$(document).ready(function () {
  var auth_token = $("meta[name=csrf-token]").attr("content");
  $("form input[name=authenticity_token]").val(auth_token);
});
