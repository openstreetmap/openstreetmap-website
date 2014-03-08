L.OSM.query = function (options) {
  var control = L.control(options);

  control.onAdd = function (map) {
    var $container = $('<div>')
      .attr('class', 'control-query');

    var link = $('<a>')
      .attr('class', 'control-button')
      .attr('href', '#')
      .attr('data-original-title', I18n.t('javascripts.site.queryfeature_tooltip'))
      .html('<span class="icon query"></span>')
      .appendTo($container);

    return $container[0];
  };

  return control;
};
