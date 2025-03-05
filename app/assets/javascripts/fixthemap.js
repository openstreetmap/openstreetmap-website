$(function () {
  const params = new URLSearchParams(location.search);

  if (!params.has("zoom")) params.set("zoom", 17);
  if (params.has("lat") && params.has("lon")) {
    $("a.new-note")[0].href += OSM.formatHash(params);
  }
});
