//= require leaflet.maplibre

L.OSM.OpenMapTiles = L.MaplibreGL.extend({
  initialize: function (options) {
    L.MaplibreGL.prototype.initialize.call(this, {
      maxZoom: 23,
      style:
        "https://api.maptiler.com/maps/openstreetmap/style.json?key=" +
        options.apikey,
      ...options
    });
  },
  onAdd: function (map) {
    L.MaplibreGL.prototype.onAdd.call(this, map);
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
    L.MaplibreGL.prototype.onRemove.call(this, map);
  }
});
