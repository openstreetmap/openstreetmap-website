$(document).ready(function () {
  $("#open_map_key").click(function (e) {
    e.preventDefault();

    var url = $(this).attr('href'),
        title = $(this).text();

    function updateMapKey() {
      var mapLayer = getMapBaseLayer().keyid,
          mapZoom = map.getZoom();

      $(".mapkey-table-entry").each(function () {
        var data = $(this).data();

        if (mapLayer == data.layer &&
            mapZoom >= data.zoomMin && mapZoom <= data.zoomMax) {
          $(this).show();
        } else {
          $(this).hide();
        }
      });
    }

    $("#sidebar_content").load(url, updateMapKey);

    openSidebar({ title: title });

    $("#sidebar").one("closed", function () {
      map.off("zoomend layeradd layerremove", updateMapKey);
    });

    map.on("zoomend layeradd layerremove", updateMapKey);
  });
});
