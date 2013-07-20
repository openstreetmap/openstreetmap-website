L.OSM.sidebar = function(selector) {
  var control = {},
    sidebar = $(selector),
    current = $(),
    map;

  control.addTo = function (_) {
    map = _;
    return control;
  };

  control.addPane = function(pane) {
    pane
      .hide()
      .appendTo(sidebar);
  };

  control.togglePane = function(pane) {
    current
      .hide()
      .trigger('hide');

    if (current === pane) {
      $(sidebar).hide();
      current = $();
    } else {
      $(sidebar).show();
      current = pane;
    }

    map.invalidateSize({pan: false, animate: false});

    current
      .show()
      .trigger('show');
  };

  return control;
};
