//= require @maplibre/maplibre-gl-leaflet

maplibregl.setRTLTextPlugin(OSM.RTL_TEXT_PLUGIN, true);

L.OSM.MaplibreGL = L.MaplibreGL.extend({
  getAttribution: function () {
    return this.options.attribution;
  }
});
