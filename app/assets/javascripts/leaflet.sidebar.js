L.OSM.sidebar = function (selector) {
  var control = {},
    sidebar = $(selector),
    current = $(),
    currentButton = $(),
    map;

  control.addTo = function (_) {
    map = _;
    return control;
  };

  control.addPane = function (pane) {
    pane
      .hide()
      .appendTo(sidebar);
  };

  control.togglePane = function (pane, button) {
    current
      .hide()
      .trigger("hide");

    currentButton
      .removeClass("active");

    if (current === pane) {
      $(sidebar).hide();
      current = currentButton = $();
    } else {
      $(sidebar).show();
      current = pane;
      currentButton = button || $();
    }

    map.invalidateSize({ pan: false, animate: false });

    current
      .show()
      .trigger("show");

    currentButton
      .addClass("active");
  };

  return control;
};
