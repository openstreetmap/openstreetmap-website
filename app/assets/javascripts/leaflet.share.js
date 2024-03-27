L.OSM.share = function (options) {
  var control = L.control(options);

  control.onAdd = function () {
    var $container = $("<div>")
      .attr("class", "control-share");

    $("<a>")
      .attr("class", "control-button")
      .attr("href", "#")
      .attr("title", I18n.t("javascripts.share.title"))
      .html("<span class=\"icon share\"></span>")
      .appendTo($container);

    return $container[0];
  };

  return control;
};
