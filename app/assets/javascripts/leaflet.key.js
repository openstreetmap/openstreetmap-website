L.OSM.key = function (options) {
  var control = L.OSM.sidebarPane(options);

  control.onAdd = function (map) {
    var $container = $("<div>")
      .attr("class", "control-key");

    var button = this.makeButton("key", null, toggle)
      .appendTo($container);

    var $ui = this.makeUI("key-ui", "javascripts.key.title", toggle);

    var $section = $("<div>")
      .attr("class", "section")
      .appendTo($ui);

    options.sidebar.addPane($ui);

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

    function toggle(e) {
      e.stopPropagation();
      e.preventDefault();
      if (!button.hasClass("disabled")) {
        options.sidebar.togglePane($ui, button);
      }
      $(".leaflet-control .control-button").tooltip("hide");
    }

    function updateButton() {
      var disabled = ["mapnik", "cyclemap"].indexOf(map.getMapBaseLayerId()) === -1;
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
        if (layer === data.layer && zoom >= data.zoomMin && zoom <= data.zoomMax) {
          $(this).show();
        } else {
          $(this).hide();
        }
      });
    }

    return $container[0];
  };

  return control;
};
