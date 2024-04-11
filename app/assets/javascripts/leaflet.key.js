L.OSM.key = function (options) {
  var control = L.OSM.sidebarPane(options, "key", null, "javascripts.key.title");

  control.onAddPane = function (map, button, $ui) {
    var $section = $("<div>")
      .attr("class", "p-3")
      .appendTo($ui);

    $ui
      .on("show", shown)
      .on("hide", hidden);

    map.on("baselayerchange", updateButton);

    updateButton();

    function shown() {
      map.on("zoomend baselayerchange", update);
      $section.load("/key", update);
    }

    function hidden() {
      map.off("zoomend baselayerchange", update);
    }

    function updateButton() {
      var disabled = OSM.LAYERS_WITH_MAP_KEY.indexOf(map.getMapBaseLayerId()) === -1;
      button
        .toggleClass("disabled", disabled)
        .attr("data-bs-original-title",
              I18n.t(disabled ?
                "javascripts.key.tooltip_disabled" :
                "javascripts.key.tooltip"));
    }

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
  };

  return control;
};
