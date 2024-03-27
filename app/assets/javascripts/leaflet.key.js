L.OSM.key = function (options) {
  var control = L.control(options);

  control.onAdd = function (map) {
    var $container = $("<div>")
      .attr("class", "control-key");

    var link = $("<a>")
      .attr("class", "control-button")
      .attr("href", "#")
      .html("<span class=\"icon key\"></span>")
      .appendTo($container);

    map.on("baselayerchange", update);

    function update() {
      var disabled = OSM.LAYERS_WITH_MAP_KEY.indexOf(map.getMapBaseLayerId()) === -1;
      link
        .toggleClass("disabled", disabled)
        .attr("data-bs-original-title",
              I18n.t(disabled ?
                "javascripts.key.tooltip_disabled" :
                "javascripts.key.tooltip"));
    }

    update();

    return $container[0];
  };

  return control;
};
