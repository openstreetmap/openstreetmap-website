function updatelinks(lon,lat,zoom,layers) {
  var node;

  node = document.getElementById("viewanchor");
  if (node) {
    var args = getArgs(node.href);
    args["lat"] = lat;
    args["lon"] = lon;
    args["zoom"] = zoom;
    args["layers"] = layers;
    node.href = setArgs(node.href, args);
  }

  node = document.getElementById("editanchor");
  if (node) {
    if (zoom >= 11) {
      var args = new Object();
      args.lat = lat;
      args.lon = lon;
      args.zoom = zoom;
      node.href = setArgs("/edit.html", args);
      node.style.fontStyle = 'normal';
    } else {
      node.href = 'javascript:alert("zoom in to edit map");';
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
