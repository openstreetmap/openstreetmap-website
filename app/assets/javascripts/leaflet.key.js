L.OSM.key = function(options) {
  var control = L.control(options);

  control.onAdd = function (map) {
    var $container = $('<div>')
      .attr('class', 'control-key');

    $('<a>')
      .attr('class', 'control-button')
      .attr('href', '#')
      .attr('title', 'Map Key')
      .html('<span class="icon key"></span>')
      .appendTo($container);

    return $container[0];
  };

  return control;
};
