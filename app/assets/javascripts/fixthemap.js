$(document).ready(function () {
  var params = OSM.params();

  var url = "/note/new";
  if (params.lat && params.lon) {
    params.lat = parseFloat(params.lat);
    params.lon = parseFloat(params.lon);
    params.zoom = params.zoom || 17;
    url += OSM.formatHash(params);
  }
  $(".icon.note").attr("href", url);
});
