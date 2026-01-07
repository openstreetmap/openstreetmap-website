OSM.MapLibre.setOMTMapLanguage = function (map) {
  if (!map.style.loaded()) {
    map.once("load", () => OSM.MapLibre.setOMTMapLanguage(map));
    return;
  }

  for (const preferredLanguage of OSM.preferred_languages) {
    const normalizedPreferredLanguage = preferredLanguage
      .toLowerCase()
      .replace("-", "_");
    // supportedLanguages and setLanguage come from @maptiler/maplibre-gl-omt-language
    const matchedLanguage = map.supportedLanguages.find(
      (supported) => supported.toLowerCase() === normalizedPreferredLanguage
    );
    if (matchedLanguage) {
      map.setLanguage(matchedLanguage);
      break;
    }
  }
};
