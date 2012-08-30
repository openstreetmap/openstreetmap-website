$(document).ready(function () {
  $("#open_map_key").click(function (e) {
    var url = $(this).attr('href'),
        title = $(this).text();

    function updateMapKey() {
      $("#sidebar_content").load(url, {
        layer: map.baseLayer.keyid,
        zoom: map.getZoom()
      });
    }

    updateMapKey();
    openSidebar({ title: title });

    $("#sidebar").one("closed", function () {
      map.events.unregister("zoomend", map, updateMapKey);
      map.events.unregister("changelayer", map, updateMapKey);
    });

    map.events.register("zoomend", map, updateMapKey);
    map.events.register("changelayer", map, updateMapKey);

    e.preventDefault();
  });
});
