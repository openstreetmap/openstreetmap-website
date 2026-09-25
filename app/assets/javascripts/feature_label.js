OSM.featurePrefix = function (feature) {
  const tags = feature.tags || {};

  if (tags.boundary === "administrative" && (tags.border_type || tags.admin_level)) {
    return OSM.i18n.t("geocoder.search_osm_nominatim.border_types." + tags.border_type, {
      defaultValue: OSM.i18n.t("geocoder.search_osm_nominatim.admin_levels.level" + tags.admin_level, {
        defaultValue: OSM.i18n.t("geocoder.search_osm_nominatim.prefix.boundary.administrative")
      })
    });
  }

  const prefixes = OSM.i18n.t("geocoder.search_osm_nominatim.prefix");

  // Prefer an exact value mapping from any tag before falling back to a
  // title-cased value of the first tag that has a prefix group.
  for (const key in tags) {
    if (prefixes[key]?.[tags[key]]) return prefixes[key][tags[key]];
  }
  for (const key in tags) {
    if (prefixes[key]) {
      const value = tags[key];
      return value.slice(0, 1).toUpperCase() + value.slice(1).replace(/_/g, " ");
    }
  }

  return OSM.i18n.t("javascripts.query." + feature.type);
};

OSM.featureName = function (feature) {
  const tags = feature.tags || {},
        localeKeys = (OSM.preferred_languages || []).map(locale => `name:${locale}`);

  for (const key of [...localeKeys, "name", "ref", "addr:housename"]) {
    if (tags[key]) return tags[key];
  }
  if (tags["addr:housenumber"] && tags["addr:street"]) return `${tags["addr:housenumber"]} ${tags["addr:street"]}`;

  return "#" + feature.id;
};
