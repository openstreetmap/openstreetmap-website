L.OSM.query = function (options) {
  const control = L.control(options);

  control.onAdd = function (map) {
    const $container = $("<div>")
      .attr("class", "control-query");

    const link = $("<a>")
      .attr("class", "control-button")
      .attr("href", "#")
      .html("<span class=\"icon query\"></span>")
      .appendTo($container);

    map.on("zoomend", update);

    function update() {
      const wasDisabled = link.hasClass("disabled"),
            isDisabled = map.getZoom() < 14;
      link
        .toggleClass("disabled", isDisabled)
        .attr("data-bs-original-title", OSM.i18n.t(isDisabled ?
          "javascripts.site.queryfeature_disabled_tooltip" :
          "javascripts.site.queryfeature_tooltip"));
      if (isDisabled === wasDisabled) return;
      link.trigger(isDisabled ? "disabled" : "enabled");
    }

    update();

    return $container[0];
  };

  return control;
};
