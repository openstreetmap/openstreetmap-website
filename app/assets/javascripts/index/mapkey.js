OSM.MapKey = function (map) {
  var page = {},
      mapKeyButton = $(".control-key .control-button");

  mapKeyButton.on("click", function (e) {
    e.preventDefault();
    e.stopPropagation();

    if ($(this).hasClass("disabled")) return;

    OSM.router.route("/mapkey");
  });

  function update() {
    var layer = map.getMapBaseLayerId(),
        zoom = map.getZoom();

    $(".mapkey-table-entry").each(function () {
      var data = $(this).data();
      $(this).toggle(
        layer === data.layer &&
        (!data.zoomMin || zoom >= data.zoomMin) &&
        (!data.zoomMax || zoom <= data.zoomMax)
      );
    });
  }

  page.pushstate = page.popstate = function (path) {
    OSM.loadSidebarContent(path, page.load);
  };

  page.load = function () {
    mapKeyButton.addClass("active");
    map.on("zoomend baselayerchange", update);
    $("#mapkey_contents").load("/key", update);
  };

  page.unload = function () {
    map.off("zoomend baselayerchange", update);
    mapKeyButton.removeClass("active");
  };

  return page;
};
