/*
 * Called as the user scrolls/zooms around to aniplate hrefs of the
 * view tab and various other links
 */
function updatelinks(lon,lat,zoom,layers,minlon,minlat,maxlon,maxlat,objtype,objid) {
  var decimals = Math.pow(10, Math.floor(zoom/3));
  var node;

  lat = Math.round(lat * decimals) / decimals;
  lon = Math.round(lon * decimals) / decimals;

  node = $("permalinkanchor");
  if (node) {
    var args = getArgs(node.href);
    args["lat"] = lat;
    args["lon"] = lon;
    args["zoom"] = zoom;
    if (layers) {
      args["layers"] = layers;
    }
    if (objtype && objid) {
      args[objtype] = objid;
    }
    node.href = setArgs(node.href, args);
  }

  node = $("viewanchor");
  if (node) {
    var args = getArgs(node.href);
    args["lat"] = lat;
    args["lon"] = lon;
    args["zoom"] = zoom;
    if (layers) {
      args["layers"] = layers;
    }
    node.href = setArgs(node.href, args);
  }

  node = $("exportanchor");
  if (node) {
    var args = getArgs(node.href);
    args["lat"] = lat;
    args["lon"] = lon;
    args["zoom"] = zoom;
    if (layers) {
      args["layers"] = layers;
    }
    node.href = setArgs(node.href, args);
  }

  node = $("editanchor");
  if (node) {
    if (zoom >= 13) {
      var args = new Object();
      args.lat = lat;
      args.lon = lon;
      args.zoom = zoom;
      if (objtype && objid) {
        args[objtype] = objid;
      }
      node.href = setArgs("/edit", args);
      node.title = i18n("javascripts.site.edit_tooltip");
      node.removeClassName("disabled");
    } else {
      node.href = 'javascript:alert(i18n("javascripts.site.edit_zoom_alert"));';
      node.title = i18n("javascripts.site.edit_disabled_tooltip");
      node.addClassName("disabled");
    }
  }

  node = $("potlatchanchor");
  if (node) {
    var args = new Object();
    args.editor = "potlatch";
    args.lat = lat;
    args.lon = lon;
    args.zoom = zoom;
    if (objtype && objid) {
      args[objtype] = objid;
    }
    node.href = setArgs("/edit", args);
  }

  node = $("potlatch2anchor");
  if (node) {
    var args = new Object();
    args.editor = "potlatch2";
    args.lat = lat;
    args.lon = lon;
    args.zoom = zoom;
    if (objtype && objid) {
      args[objtype] = objid;
    }
    node.href = setArgs("/edit", args);
  }

  node = $("josmanchor");
  if (node) {
    var args = new Object();
    args.editor = "josm";
    args.lat = lat;
    args.lon = lon;
    args.zoom = zoom;
    if (objtype && objid) {
      args[objtype] = objid;
    }
    node.href = setArgs("/edit", args);
  }

  node = $("historyanchor");
  if (node) {
    if (zoom >= 11) {
      var args = new Object();
      //set bbox param from 'extents' object
      if (typeof minlon == "number" &&
          typeof minlat == "number" &&
          typeof maxlon == "number" &&
          typeof maxlat == "number") {

        minlon = Math.round(minlon * decimals) / decimals;
        minlat = Math.round(minlat * decimals) / decimals;
        maxlon = Math.round(maxlon * decimals) / decimals;
        maxlat = Math.round(maxlat * decimals) / decimals;
        args.bbox = minlon + "," + minlat + "," + maxlon + "," + maxlat;
      }

      node.href = setArgs("/history", args);
      node.title = i18n("javascripts.site.history_tooltip");
      node.removeClassName("disabled");
    } else {
      node.href = 'javascript:alert(i18n("javascripts.site.history_zoom_alert"));';
      node.title = i18n("javascripts.site.history_disabled_tooltip");
      node.addClassName("disabled");
    }
  }

  node = $("shortlinkanchor");
  if (node) {
    var args = getArgs(node.href);
    var code = makeShortCode(lat, lon, zoom);
    var prefix = shortlinkPrefix();

    // Add ?{node,way,relation}=id to the arguments
    if (objtype && objid) {
      args[objtype] = objid;
    }

    // This is a hack to omit the default mapnik layer from the shortlink.
    if (layers && layers != "M") {
      args["layers"] = layers;
    }
    else {
      delete args["layers"];
    }

    // Here we're assuming that all parameters but ?layers= and
    // ?{node,way,relation}= can be safely omitted from the shortlink
    // which encodes lat/lon/zoom. If new URL parameters are added to
    // the main slippy map this needs to be changed.
    if (args["layers"] || args[objtype]) {
      node.href = setArgs(prefix + "/go/" + code, args);
    } else {
      node.href = prefix + "/go/" + code;
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
  var args = new Object();
  var querystart = url.indexOf("?");

  if (querystart >= 0) {
     var querystring = url.substring(querystart + 1);
     var queryitems = querystring.split("&");

     for (var i = 0; i < queryitems.length; i++) {
        if (match = queryitems[i].match(/^(.*)=(.*)$/)) {
           args[unescape(match[1])] = unescape(match[2]);
        } else {
           args[unescape(queryitems[i])] = null
        }
     }
  }

  return args;
}

/*
 * Called to set the arguments on a URL from the given hash.
 */
function setArgs(url, args) {
   var queryitems = new Array();

   for (arg in args)
   {
      if (args[arg] == null) {
         queryitems.push(escape(arg));
      } else {
         queryitems.push(escape(arg) + "=" + escape(args[arg]));
      }
   }

   return url.replace(/\?.*$/, "") + "?" + queryitems.join("&");
}

/*
 * Called to get a CSS property for an element.
 */
function getStyle(el, property) {
  var style;

  if (el.currentStyle) {
    style = el.currentStyle[property];
  } else if( window.getComputedStyle ) {
    style = document.defaultView.getComputedStyle(el,null).getPropertyValue(property);
  } else {
    style = el.style[property];
  }

  return style;
}

/*
 * Called to interpolate JavaScript variables in strings using a
 * similar syntax to rails I18n string interpolation - the only
 * difference is that [[foo]] is the placeholder syntax instead
 * of {{foo}} which allows the same string to be processed by both
 * rails and then later by javascript.
 */
function i18n(string, keys) {
  string = i18n_strings[string] || string

  for (var key in keys) {
    var re_key = '\\[\\[' + key + '\\]\\]';
    var re = new RegExp(re_key, "g");

    string = string.replace(re, keys[key]);
  }

  return string;
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
    char_array = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_@";
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
