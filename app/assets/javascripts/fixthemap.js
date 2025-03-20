$(function () {
  const params = new URLSearchParams(location.search);

  let url = "/note/new";
  if (!params.has("zoom")) params.set("zoom", 17);
  if (params.has("lat") && params.has("lon")) url += OSM.formatHash(params);
  $(".icon.note").attr("href", url);
});
