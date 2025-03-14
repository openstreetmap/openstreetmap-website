$(function () {
  const params = OSM.params();

  if (!params.zoom) params.zoom = 17;
  if (params.lat && params.lon) {
    $("a.new-note")[0].href += OSM.formatHash(params);
  }
});
