$(function () {
  const params = OSM.params();

  let url = "/note/new";
  if (!params.zoom) params.zoom = 17;
  if (params.lat && params.lon) url += OSM.formatHash(params);
  $(".icon.note").attr("href", url);
});
