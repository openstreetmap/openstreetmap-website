L.OSM.hideNotes = function (options) {
  const control = L.control(options);

  control.onAdd = function (map) {
    const $container = $("<div>")
      .attr("class", "control-hide-notes position-relative");

    const link = $("<a>")
      .attr("class", "control-button")
      .attr("href", "#")
      .attr("title", OSM.i18n.t("javascripts.site.hidenotes_tooltip"))
      .append($("<i>").addClass("fs-5 bi bi-chat-square-text").css({ position: 'absolute', bottom: '25%', left: '20%' }))
      .append($("<i>").addClass("fs-6 bi bi-eye-slash-fill").css({ position: 'absolute', top: '0%', right: '5%' }))
      .appendTo($container);

    link.on("click", function (e) {
      e.preventDefault();
      map.removeLayer(map.noteLayer);
    });

    map.on("overlayadd overlayremove", updateVisibility);

    function updateVisibility() {
      $container.toggle(map.hasLayer(map.noteLayer));
    }

    updateVisibility();

    return $container[0];
  };

  return control;
};