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

    $('<div>')
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

    var $linkSection = $('<div>')
      .attr('class', 'section share-link')
      .appendTo($ui);

    $('<h4>')
      .text(I18n.t('javascripts.share.link'))
      .appendTo($linkSection);

    var $shortLink, $longLink;

    $('<ul>')
      .appendTo($linkSection)
      .append($('<li>')
        .append($longLink = $('<a>')
          .text(I18n.t('javascripts.share.long_link'))))
      .append($('<li>')
        .append($shortLink = $('<a>')
          .text(I18n.t('javascripts.share.short_link'))));

    map.on('moveend layeradd layerremove', update);

    options.sidebar.addPane($ui);

    function toggle(e) {
      e.stopPropagation();
      e.preventDefault();
      options.sidebar.togglePane($ui);
      update();
    }

    function update() {
      $shortLink.attr('href', options.getShortUrl(map));
      $longLink.attr('href', options.getUrl(map));
    }

    function select() {
      $(this).select();
    }

    return $container[0];
  };

  return control;
};
