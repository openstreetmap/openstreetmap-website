L.OSM.key = function (options) {
  var control = L.control(options);

  control.onAdd = function (map) {
    var $container = $('<div>')
      .attr('class', 'control-key');

    $('<a>')
      .attr('class', 'control-button')
      .attr('href', '#')
      .attr('title', I18n.t('javascripts.key.tooltip'))
      .html('<span class="icon key"></span>')
      .on('click', toggle)
      .appendTo($container);

    var $ui = $('<div>')
      .attr('class', 'key-ui');

    $('<header>')
      .attr('class', 'sidebar_heading')
      .appendTo($ui)
      .append(
        $('<a>')
          .text(I18n.t('javascripts.close'))
          .attr('class', 'sidebar_close')
          .attr('href', '#')
          .bind('click', toggle))
      .append(
        $('<h4>')
          .text(I18n.t('javascripts.key.title')));

    var $section = $('<section>')
      .appendTo($ui);

    options.sidebar.addPane($ui);

    $ui
      .on('show', shown)
      .on('hide', hidden);

    function shown() {
      map.on('zoomend baselayerchange', update);
      $section.load('/key', update);
    }

    function hidden() {
      map.off('zoomend baselayerchange', update);
    }

    function toggle(e) {
      e.stopPropagation();
      e.preventDefault();
      options.sidebar.togglePane($ui);
    }

    function update() {
      var layer = map.getMapBaseLayerId(),
        zoom = map.getZoom();

      $('.mapkey-table-entry').each(function () {
        var data = $(this).data();
        if (layer == data.layer && zoom >= data.zoomMin && zoom <= data.zoomMax) {
          $(this).show();
        } else {
          $(this).hide();
        }
      });
    }

    return $container[0];
  };

  return control;
};
