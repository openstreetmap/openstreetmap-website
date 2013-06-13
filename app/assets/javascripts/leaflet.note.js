L.OSM.note = function (options) {
  var control = L.control(options);

  control.onAdd = function (map) {
    var $container = $('<div>')
      .attr('class', 'control-note');

    $('<a>')
      .attr('class', 'control-button')
      .attr('href', '#')
      .attr('title', I18n.t('javascripts.notes.new.add'))
      .html('<span class="icon note"></span>')
      .appendTo($container);

    return $container[0];
  };

  return control;
};
