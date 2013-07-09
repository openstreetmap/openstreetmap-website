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
          .text(I18n.t('javascripts.share.title')));

    var $share_link = $('<section>')
      .appendTo($ui);

    var $title = $('<h4>')
      .text(I18n.t('javascripts.share.link'))
      .appendTo($share_link);

    var $input = $('<input />')
      .attr('type', 'text')
      .on('click', select)
      .appendTo($share_link);

    var $list = $('<ul>')
      .appendTo($share_link);

    var $short_option = $('<li>')
      .appendTo($list);

    var $short_url_label = $('<label></label>')
      .attr('for', 'short_url')
      .appendTo($short_option);

    var $short_url_input = $('<input />')
      .attr('id', 'short_url')
      .attr('type', 'checkbox')
      .prop('checked', 'checked')
      .appendTo($short_url_label)
      .bind('change', function() {
          options.short = $(this).prop('checked');
          update();
      });

    $short_url_label.append(I18n.t('javascripts.share.short_url'));

    map.on('moveend layeradd layerremove', update);

    options.sidebar.addPane($ui);

    function toggle(e) {
      e.stopPropagation();
      e.preventDefault();
      options.sidebar.togglePane($ui);
      $input.select();
    }

    function update() {
      $input.val(
          options.short ? options.getShortUrl(map) : options.getUrl(map)
      );
    }

    function select() {
      $(this).select();
    }

    return $container[0];
  };

  return control;
};
