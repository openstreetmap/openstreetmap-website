var map;
var markers;
var popup;

function createMap(divName) {
   OpenLayers.Util.onImageLoadError = function() {
      this.src = OpenLayers.Util.getImagesLocation() + "404.png";
   }

   map = new OpenLayers.Map(divName,
                            { maxExtent: new OpenLayers.Bounds(-20037508,-20037508,20037508,20037508),
                              numZoomLevels: 19,
                              maxResolution: 156543,
                              units: 'm',
                              projection: "EPSG:41001" });

   var mapnik = new OpenLayers.Layer.TMS("Mapnik",
                                         ["http://a.tile.openstreetmap.org/","http://b.tile.openstreetmap.org/","http://c.tile.openstreetmap.org/"],
                                         { type: 'png', getURL: getTileURL, displayOutsideMaxExtent: true });
   map.addLayer(mapnik);

   var osmarender = new OpenLayers.Layer.TMS("Osmarender",
                                             "http://dev.openstreetmap.org/~ojw/Tiles/tile.php/",
                                             { type: 'png', getURL: getTileURL, displayOutsideMaxExtent: true });
   map.addLayer(osmarender);

   markers = new OpenLayers.Layer.Markers("markers", { visibility: false });
   map.addLayer(markers);

   map.addControl(new OpenLayers.Control.LayerSwitcher());

   return map;
}

function getTileURL(bounds) {
   var res = this.map.getResolution();
   var x = Math.round((bounds.left - this.maxExtent.left) / (res * this.tileSize.w));
   var y = Math.round((this.maxExtent.top - bounds.top) / (res * this.tileSize.h));
   var z = this.map.getZoom();
   var limit = Math.pow(2, z);

   if (y < 0 || y >= limit)
   {
     return OpenLayers.Util.getImagesLocation() + "404.png";
   }
   else
   {
     x = ((x % limit) + limit) % limit;

     var url = this.url;
     var path = z + "/" + x + "/" + y + "." + this.type;

     if (url instanceof Array)
     {
        url = this.selectUrl(path, url);
     }

     return url + path;
   }
}

function getArrowIcon() {
   var size = new OpenLayers.Size(25, 22);
   var offset = new OpenLayers.Pixel(-30, -27);
   var icon = new OpenLayers.Icon("/images/arrow.png", size, offset);

   return icon;
}

function addMarkerToMap(position, icon, description) {
   var marker = new OpenLayers.Marker(position, icon);

   markers.addMarker(marker);
   markers.setVisibility(true);

   if (description) {
      marker.events.register("click", marker, function() { openMapPopup(marker, description) });
   }

   return marker;
}

function openMapPopup(marker, description) {
   closeMapPopup();

   popup = new OpenLayers.Popup.AnchoredBubble("popup", marker.lonlat,
                                               sizeMapPopup(description),
                                               "<p style='padding-right: 28px'>" + description + "</p>",
                                               marker.icon, true);
   popup.setBackgroundColor("#E3FFC5");
   map.addPopup(popup);

   return popup;
}

function closeMapPopup() {
   if (popup) {
      map.removePopup(popup);
      delete popup;
   }
}

function sizeMapPopup(text) {
   var box = document.createElement("div");

   box.innerHTML = text;
   box.style.visibility = "hidden";
   box.style.position = "absolute";
   box.style.top = "0px";
   box.style.left = "0px";
   box.style.width = "200px";
   box.style.height = "auto";

   document.body.appendChild(box);

   var width = box.offsetWidth;
   var height = box.offsetHeight;

   document.body.removeChild(box);

   return new OpenLayers.Size(width + 30, height + 24);
}

function removeMarkerFromMap(marker){
   markers.removeMarker(marker);
}

function getMapLayers() {
   var layers = "";

   for (var i=0; i< this.map.layers.length; i++) {
      var layer = this.map.layers[i];

      if (layer.isBaseLayer) {
         layers += (layer == this.map.baseLayer) ? "B" : "0";
      } else {
         layers += (layer.getVisibility()) ? "T" : "F";
      }
   }

   return layers;
}

function setMapLayers(layers) {
   for (var i=0; i < layers.length; i++) {
      var layer = map.layers[i];
      var c = layers.charAt(i);

      if (c == "B") {
         map.setBaseLayer(layer);
      } else if ( (c == "T") || (c == "F") ) {
         layer.setVisibility(c == "T");
      }
   }
}

function mercatorToLonLat(merc) {
   var lon = (merc.lon / 20037508.34) * 180;
   var lat = (merc.lat / 20037508.34) * 180;

   lat = 180/Math.PI * (2 * Math.atan(Math.exp(lat * Math.PI / 180)) - Math.PI / 2);

   return new OpenLayers.LonLat(lon, lat);
}

function lonLatToMercator(ll) {
   var lon = ll.lon * 20037508.34 / 180;
   var lat = Math.log(Math.tan((90 + ll.lat) * Math.PI / 360)) / (Math.PI / 180);

   lat = lat * 20037508.34 / 180;

   return new OpenLayers.LonLat(lon, lat);
}

function scaleToZoom(scale) {
   return Math.log(360.0/(scale * 512.0)) / Math.log(2.0);
}
