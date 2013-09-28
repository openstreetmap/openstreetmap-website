function maximiseMap() {
  $("#content").addClass("maximised");
}

function minimiseMap() {
  $("#content").removeClass("maximised");
}

$(document).ready(function () {
  $("#search_form").submit(function (e) {
    e.preventDefault();

    $("#sidebar_content").load($(this).attr("action"), {
      query: $("#query").val()
    });
  });

  $("#describe_location").click(function (e) {
    e.preventDefault();

    var mapParams = OSM.mapParams();

    $("#sidebar_content").load($(this).attr("href"), {
      lat: mapParams.lat,
      lon: mapParams.lon,
      zoom: mapParams.zoom
    });
  });
});
