L.OSM.note = function (options) {
  var control = L.control(options);

  control.onAdd = function (map) {
    var $container = $('<div>')
      .attr('class', 'control-note');

    $('<a>')
      .attr('class', 'control-button')
      .attr('href', '#')
      .attr('title', 'Notes')
      .html('<span class="icon note"></span>')
      .on('click', toggle)
      .appendTo($container);

    function toggle(e) {
      e.stopPropagation();
      e.preventDefault();

      if (map.hasLayer(map.noteLayer)) {
        map.removeLayer(map.noteLayer);
      } else {
        map.addLayer(map.noteLayer);
      }
    }

    return $container[0];
  };

  return control;
};
