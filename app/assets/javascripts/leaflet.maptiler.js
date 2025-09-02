//= require leaflet.maplibre
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
    const maplibreMap = this.getMaplibreMap();
    const supportedLanguages = maplibregl.Map.prototype.supportedLanguages;
    for (const preferredLanguage of OSM.preferred_languages) {
      const normalizedPreferredLanguage = preferredLanguage
        .toLowerCase()
        .replace("-", "_");
      const matchedLanguage = supportedLanguages.find(
        (supported) => supported.toLowerCase() === normalizedPreferredLanguage
      );
      if (matchedLanguage) {
        maplibreMap.setLanguage(matchedLanguage);
        break;
      }
    }
  },
  onRemove: function (map) {
    L.OSM.MaplibreGL.prototype.onRemove.call(this, map);
  }
});
