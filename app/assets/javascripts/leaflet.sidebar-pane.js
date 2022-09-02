L.OSM.sidebarPane = function (options, uiClass, buttonTitle, paneTitle) {
  var control = L.control(options);

  control.onAdd = function (map) {
    var $container = $("<div>")
      .attr("class", "control-" + uiClass);

    var button = $("<a>")
      .attr("class", "control-button")
      .attr("href", "#")
      .html("<span class=\"icon " + uiClass + "\"></span>")
      .on("click", toggle);

    if (buttonTitle) {
      button.attr("title", I18n.t(buttonTitle));
    }

    button.appendTo($container);

    var $ui = $("<div>")
      .attr("class", uiClass + "-ui");

    $("<div class='sidebar_heading d-flex'>")
      .appendTo($ui)
      .append($("<div class='flex-grow-1 text-break'>")
        .append($("<h4>")
          .text(I18n.t(paneTitle))))
      .append($("<div>")
        .append($("<button type='button' class='btn-close'>")
          .attr("aria-label", I18n.t("javascripts.close"))
          .bind("click", toggle)));

    options.sidebar.addPane($ui);

    this.onAddPane(map, button, $ui, toggle);

    function toggle(e) {
      e.stopPropagation();
      e.preventDefault();
      if (!button.hasClass("disabled")) {
        options.sidebar.togglePane($ui, button);
      }
      $(".leaflet-control .control-button").tooltip("hide");
    }

    return $container[0];
  };

  // control.onAddPane = function (map, button, $ui, toggle) {
  // }

  return control;
};
