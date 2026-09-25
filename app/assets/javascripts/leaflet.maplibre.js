//= require @maplibre/maplibre-gl-leaflet

maplibregl.setRTLTextPlugin(OSM.MODULE_PATHS.mapbox_rtl_text, true);

L.OSM.MaplibreGL = L.MaplibreGL.extend({
  getAttribution: function () {
    return this.options.attribution;
  }
});
