L.OSM.sidebarPane = function (options) {
  var control = L.control(options);

  control.makeUI = function (uiClass, paneTitle, toggle) {
    var $ui = $("<div>")
      .attr("class", uiClass);

    $("<div>")
      .attr("class", "sidebar_heading")
      .appendTo($ui)
      .append(
        $("<button type='button' class='btn-close float-end mt-1'>")
          .attr("aria-label", I18n.t("javascripts.close"))
          .bind("click", toggle))
      .append(
        $("<h4>")
          .text(I18n.t(paneTitle)));

    return $ui;
  };

  return control;
};
