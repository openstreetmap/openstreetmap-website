/*
 * Called as the user scrolls/zooms around to aniplate hrefs of the
 * view tab and various other links
 */
function updatelinks(lon,lat,zoom,layers,minlon,minlat,maxlon,maxlat) {
  var decimals = Math.pow(10, Math.floor(zoom/3));
  var node;

  lat = Math.round(lat * decimals) / decimals;
  lon = Math.round(lon * decimals) / decimals;

  node = document.getElementById("permalinkanchor");
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

  node = document.getElementById("viewanchor");
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

  node = document.getElementById("exportanchor");
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

  node = document.getElementById("editanchor");
  if (node) {
    if (zoom >= 13) {
      var args = new Object();
      args.lat = lat;
      args.lon = lon;
      args.zoom = zoom;
      node.href = setArgs("/edit", args);
      node.style.fontStyle = 'normal';
    } else {
      node.href = 'javascript:alert("zoom in to edit map");';
      node.style.fontStyle = 'italic';
    }
  }
  
  node = document.getElementById("historyanchor");
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
      node.style.fontStyle = 'normal';
    } else {
      node.href = 'javascript:alert("zoom in to see editing history");';
      node.style.fontStyle = 'italic';
    }
  }
}

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
 * Called to get the arguments from a URL as a hash.
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
  for (var key in keys) {
    var re_key = '\\[\\[' + key + '\\]\\]';
    var re = new RegExp(re_key, "g");
      
    string = string.replace(re, keys[key]);
  }
   
  return string;
} 
