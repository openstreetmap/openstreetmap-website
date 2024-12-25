L.OSM.note = function (options) {
  var control = L.control(options);

  control.onAdd = function (map) {
    var $container = $("<div>")
      .attr("class", "control-note");

    var link = $("<a>")
      .attr("class", "control-button")
      .attr("href", "#")
      .html("<span class=\"icon note\"></span>")
      .appendTo($container);

    map.on("zoomend", update);

    function update() {
      var wasDisabled = link.hasClass("disabled"),
          isDisabled = OSM.STATUS === "database_offline" || map.getZoom() < 12;
      link
        .toggleClass("disabled", isDisabled)
        .attr("data-bs-original-title", I18n.t(isDisabled ?
          "javascripts.site.createnote_disabled_tooltip" :
          "javascripts.site.createnote_tooltip"));

      if (isDisabled && !wasDisabled) {
        link.trigger("disabled");
      } else if (wasDisabled && !isDisabled) {
        link.trigger("enabled");
      }
    }

    update();

    return $container[0];
  };

  return control;
};
