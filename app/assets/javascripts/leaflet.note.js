L.OSM.note = function (options) {
  const control = L.control(options);

  control.onAdd = function (map) {
    const $container = $("<div>")
      .attr("class", "control-note");

    const link = $("<a>")
      .attr("class", "control-button")
      .attr("href", "#")
      .attr("title", OSM.i18n.t("javascripts.site.createnote_tooltip"))
      .append($("<i>").addClass("fs-5 bi bi-chat-square-text-fill"))
      .appendTo($container);

    map.on("zoomend", update);

    function update() {
      const wasDisabled = link.hasClass("disabled"),
            isDisabled = OSM.STATUS === "database_offline" || map.getZoom() < 12;
      link
        .toggleClass("disabled", isDisabled)
        .attr("data-bs-original-title", OSM.i18n.t(isDisabled ?
          "javascripts.site.createnote_disabled_tooltip" :
          "javascripts.site.createnote_tooltip"));
      if (isDisabled === wasDisabled) return;
      link.trigger(isDisabled ? "disabled" : "enabled");
    }

    update();

    return $container[0];
  };

  return control;
};
