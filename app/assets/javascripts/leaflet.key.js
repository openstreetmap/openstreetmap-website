L.OSM.key = function (options) {
  const control = L.OSM.sidebarPane(options, "key", null, "javascripts.key.title");

  control.onAddPane = function (map, button, $ui) {
    const $section = $("<div>")
      .attr("class", "p-3")
      .appendTo($ui);

    $ui
      .on("show", shown)
      .on("hide", hidden);

    map.on("baselayerchange", updateButton);

    updateButton();

    function shown() {
      map.on("zoomend baselayerchange", update);
      fetch("/key")
        .then(r => r.text())
        .then(html => { $section.html(html); })
        .then(update);
    }

    function hidden() {
      map.off("zoomend baselayerchange", update);
    }

    function updateButton() {
      const disabled = OSM.LAYERS_WITH_MAP_KEY.indexOf(map.getMapBaseLayerId()) === -1;
      button
        .toggleClass("disabled", disabled)
        .attr("data-bs-original-title",
              OSM.i18n.t(disabled ?
                "javascripts.key.tooltip_disabled" :
                "javascripts.key.tooltip"));
    }

    function update() {
      const layerId = map.getMapBaseLayerId(),
            zoom = map.getZoom();

      $(".mapkey-table-entry").each(function () {
        const data = $(this).data();
        $(this).toggle(
          layerId === data.layer &&
          (!data.zoomMin || zoom >= data.zoomMin) &&
          (!data.zoomMax || zoom <= data.zoomMax)
        );
      });
    }
  };

  return control;
};
