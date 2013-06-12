L.OSM.share = function (options) {
  var control = L.control(options);

  control.onAdd = function (map) {
    var $container = $('<div>')
      .attr('class', 'control-share');

    $('<a>')
      .attr('class', 'control-button')
      .attr('href', '#')
      .attr('title', 'Share')
      .html('<span class="icon share"></span>')
      .on('click', toggle)
      .appendTo($container);

    var $ui = $('<div>')
      .attr('class', 'share-ui');

    $('<h2>')
      .text(I18n.t('javascripts.share.title'))
      .appendTo($ui);

    var $input = $('<input>')
      .appendTo($ui);

    map.on('moveend layeradd layerremove', update);

    options.sidebar.addPane($ui);

    function toggle(e) {
      e.stopPropagation();
      e.preventDefault();
      options.sidebar.togglePane($ui);
    }

    function update() {
      var center = map.getCenter().wrap();
      var layers = getMapLayers(map);
      $input.val(options.getUrl(map));
    }

    return $container[0];
  };

  return control;
};
