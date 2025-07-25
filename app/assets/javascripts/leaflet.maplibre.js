//= require maplibre-gl
//= require @maplibre/maplibre-gl-leaflet

maplibregl.setRTLTextPlugin(OSM.RTL_TEXT_PLUGIN, true);

L.OSM.MaplibreGL = L.MaplibreGL.extend({
  _getAttribution: function () {
    return this.options.attribution;
  },
  _blankAttribution: function () {
    return "";
  },
  onAdd: function (map) {
    this.getAttribution = this._blankAttribution;
    L.MaplibreGL.prototype.onAdd.call(this, map);
    this.getAttribution = this._getAttribution;
  }
});
