L.OSM.OHM = L.OSM.MaplibreGL.extend({
  initialize: function (options) {
    L.OSM.MaplibreGL.prototype.initialize.call(this, {
      localIdeographFontFamily: "'Noto Sans', 'Noto Sans CJK SC', sans-serif",
      minZoom: 1, // leave at 1 even if L.OSM.Map has something deeper
      maxZoom: 20, // match to "L.OSM.Map" options in index.js
      ...options,
    });
  },
  onAdd: function (map) {
    L.OSM.MaplibreGL.prototype.onAdd.call(this, map);

    // Add multilingual awareness
    const language = new MapboxLanguage({
      defaultLanguage: 'mul'
    });
    let selectedLanguage;
    /*
     * Note: there is no language validation at this step; OSM.preferred_languages[0] may be any arbitrary string. Even
     * if it is a valid (RFC 5646) language string it may be filtered out for being infrequently used
     * (see https://github.com/OpenHistoricalMap/issues/issues/948) and may not appear on the OHM map.
     */
    if (OSM.preferred_languages !== undefined && OSM.preferred_languages.length > 0) {
      selectedLanguage = OSM.preferred_languages[0]
    } else if (navigator.language) {
      selectedLanguage = navigator.language
    }
    if (selectedLanguage) {
      // Strip out country and script codes. Country- and script-qualified language tags are relatively rare in OHM, and mapbox-gl-language lacks cascading fallback functionality.
      // https://github.com/mapbox/mapbox-gl-language/issues/4
      selectedLanguage = selectedLanguage.split("-")[0];
    }
    // console.info(`language:\n  preferred: ${OSM.preferred_languages}\n  browser: ${navigator.language}\n  using: ${selectedLanguage}`);
    language.supportedLanguages.push(selectedLanguage);
    let style = language.setLanguage(ohmVectorStyles[this.ohmStyleName], selectedLanguage);

    this.getMaplibreMap().setStyle(style);
  },
  onRemove: function (map) {
    L.OSM.MaplibreGL.prototype.onRemove.call(this, map);
  }
});

L.OSM.Historical = L.OSM.OHM.extend({ ohmStyleName: "Historical" });
L.OSM.Railway = L.OSM.OHM.extend({ ohmStyleName: "Railway"});
L.OSM.Woodblock = L.OSM.OHM.extend({ ohmStyleName: "Woodblock" });
L.OSM.JapaneseScroll = L.OSM.OHM.extend({ ohmStyleName: "JapaneseScroll" });
