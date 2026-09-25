//= require maplibre/i18n
//= require @maptiler/maplibre-gl-omt-language

L.OSM.OpenMapTiles = L.OSM.MaplibreGL.extend({
  initialize: function (options) {
    L.OSM.MaplibreGL.prototype.initialize.call(this, {
      style:
        "https://api.maptiler.com/maps/openstreetmap/style.json?key=" +
        options.apikey,
      ...options
    });
  },
  onAdd: function (map) {
    L.OSM.MaplibreGL.prototype.onAdd.call(this, map);
    OSM.MapLibre.setOMTMapLanguage(this.getMaplibreMap());
  },
  onRemove: function (map) {
    L.OSM.MaplibreGL.prototype.onRemove.call(this, map);
  }
});
