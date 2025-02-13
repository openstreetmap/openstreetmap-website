L.OSM.sidebar = function (selector) {
  const control = {},
        sidebar = $(selector);
  let current = $(),
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
    const paneWidth = 250;

    current
      .hide()
      .trigger("hide");

    currentButton
      .removeClass("active");

    if (current === pane) {
      if ($("html").attr("dir") === "rtl") {
        map.panBy([-paneWidth, 0], { animate: false });
      }
      $(sidebar).hide();
      $("#content").addClass("overlay-right-sidebar");
      current = currentButton = $();
    } else {
      $(sidebar).show();
      $("#content").removeClass("overlay-right-sidebar");
      current = pane;
      currentButton = button || $();
      if ($("html").attr("dir") === "rtl") {
        map.panBy([paneWidth, 0], { animate: false });
      }
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
