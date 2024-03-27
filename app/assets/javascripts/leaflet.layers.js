L.OSM.layers = function (options) {
  var control = L.control(options);

  control.onAdd = function () {
    var $container = $("<div>")
      .attr("class", "control-layers");

    $("<a>")
      .attr("class", "control-button")
      .attr("href", "#")
      .attr("title", I18n.t("javascripts.map.layers.title"))
      .html("<span class=\"icon layers\"></span>")
      .appendTo($container);

    return $container[0];
  };

  return control;
};
