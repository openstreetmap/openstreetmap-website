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

    $('<section>')
      .appendTo($ui)
      .append(
      $('<h2>')
        .text(I18n.t('javascripts.share.title')));

    var $share_link = $('<section></section>')
      .appendTo($ui);

    var $title = $('<h3></h3>')
      .text(I18n.t('javascripts.share.link'))
      .appendTo($share_link);

    var $short_url_input = $('<input />')
      .attr('id', 'short_url')
      .attr('type', 'checkbox')
      .prop('checked', 'checked')
      .appendTo($share_link)
      .bind('change', function() {
          options.short = $(this).prop('checked');
          update();
      });

    var $short_url_label = $('<label></label>')
      .text(I18n.t('javascripts.share.short_url'))
      .attr('for', 'short_url')
      .appendTo($share_link);

    var $input = $('<input />')
      .appendTo($share_link);

    map.on('moveend layeradd layerremove', update);

    options.sidebar.addPane($ui);

    function toggle(e) {
      e.stopPropagation();
      e.preventDefault();
      options.sidebar.togglePane($ui);
    }

    function update() {
      $input.val(
          options.short ? options.getShortUrl(map) : options.getUrl(map)
      );
    }

    return $container[0];
  };

  return control;
};
