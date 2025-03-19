$(function () {
  const id = $("#id-embed"),
        idData = id.data();

  if (!idData.configured) {
    // eslint-disable-next-line no-alert
    alert(OSM.i18n.t("site.edit.id_not_configured"));
    return;
  }

  const hashParams = new URLSearchParams(location.hash.slice(1));
  const hashArgs = OSM.parseHash();
  const mapParams = OSM.mapParams();
  const params = new URLSearchParams();
  let zoom, lat, lon;

  if (idData.lat && idData.lon) {
    ({ zoom, lat, lon } = idData);
  } else if (!mapParams.object) {
    ({ zoom, lat, lon } = mapParams);
  }
  if (mapParams.object) {
    params.set("id", mapParams.object.type + "/" + mapParams.object.id);
    if (hashArgs.center) ({ zoom, center: { lat, lng: lon } } = hashArgs);
  }
  if (lat && lon) params.set("map", [zoom || 17, lat, lon].join("/"));

  const passThroughKeys = ["background", "comment", "disable_features", "gpx", "hashtags", "locale", "maprules", "notes", "offset", "photo", "photo_dates", "photo_overlay", "photo_username", "presets", "source", "validationDisable", "validationWarning", "validationError", "walkthrough"];
  for (const key of passThroughKeys) {
    if (hashParams.has(key)) params.set(key, hashParams.get(key));
  }

  if (mapParams.layers.includes("N")) params.set("notes", "true");

  if (idData.gpx) params.set("gpx", idData.gpx);

  id.attr("src", idData.url + "#" + params);

  id.ready(function () {
    if (!this.contentWindow.location.href.startsWith(idData.url)) {
      location.reload();
    }
  });
});
