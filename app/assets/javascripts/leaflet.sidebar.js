L.OSM.sidebar = function(selector) {
  var control = {},
    sidebar = $(selector),
    current = $();

  control.addPane = function(pane) {
    pane
      .hide()
      .appendTo(sidebar);
  };

  control.togglePane = function(pane) {
    var controlContainer = $('.leaflet-control-container .leaflet-top.leaflet-right');

    current
      .hide()
      .trigger('hide');

    if (current === pane) {
      $(sidebar).hide();
      controlContainer.css({paddingRight: '0'});
      current = $();
    } else {
      $(sidebar).show();
      controlContainer.css({paddingRight: '200px'});
      current = pane;
    }

    current
      .show()
      .trigger('show');
  };

  return control;
};
