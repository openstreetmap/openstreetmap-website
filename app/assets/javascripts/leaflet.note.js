L.OSM.note = function (options) {
  var control = L.control(options);

  control.onAdd = function (map) {
    var $container = $('<div>')
      .attr('class', 'control-note');

    $('<a>')
      .attr('id', 'createnoteanchor')
      .attr('class', 'control-button geolink')
      .attr('data-minzoom', 12)
      .attr('href', '#')
      .html('<span class="icon note"></span>')
      .appendTo($container);

    return $container[0];
  };

  return control;
};
