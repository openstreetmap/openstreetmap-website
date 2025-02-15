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
    var mediumDeviceWidth = window.getComputedStyle(document.documentElement).getPropertyValue("--bs-breakpoint-md");
    var isMediumDevice = window.matchMedia(`(max-width: ${mediumDeviceWidth})`).matches;
    var paneWidth = 250;

    current
      .hide()
      .trigger("hide");

    currentButton
      .removeClass("active");

    if (current === pane) {
      $(sidebar).hide();
      $("#content").addClass("overlay-right-sidebar");
      current = currentButton = $();
      if (isMediumDevice) {
        map.panBy([0, -$("#map").height() / 2], { animate: false });
      } else if ($("html").attr("dir") === "rtl") {
        map.panBy([-paneWidth, 0], { animate: false });
      }
    } else {
      $(sidebar).show();
      $("#content").removeClass("overlay-right-sidebar");
      current = pane;
      currentButton = button || $();
      if (isMediumDevice) {
        map.panBy([0, $("#map").height()], { animate: false });
      } else if ($("html").attr("dir") === "rtl") {
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
