L.OSM.key = function (options) {
  var control = L.control(options);

  control.onAdd = function (map) {
    var $container = $('<div>')
      .attr('class', 'control-key');

    $('<a>')
      .attr('class', 'control-button')
      .attr('href', '#')
      .attr('title', I18n.t("javascripts.key.tooltip"))
      .html('<span class="icon key"></span>')
      .on('click', toggle)
      .appendTo($container);

    var $ui = $('<div>')
      .attr('class', 'layers-ui')
      .appendTo(options.uiPane);

    $('<h2>')
      .text(I18n.t('javascripts.key.title'))
      .appendTo($ui);

    var $section = $('<section>')
      .appendTo($ui);

    function toggle(e) {
      e.stopPropagation();
      e.preventDefault();

      var controlContainer = $('.leaflet-control-container .leaflet-top.leaflet-right');

      if ($ui.is(':visible')) {
        $(options.uiPane).hide();
        controlContainer.css({paddingRight: '0'});
        map.off("zoomend baselayerchange", update);
      } else {
        $(options.uiPane).show();
        controlContainer.css({paddingRight: '200px'});
        map.on("zoomend baselayerchange", update);
        $section.load('/key', update);
      }
    }

    function update() {
      var mapLayer = getMapBaseLayerId(map),
        mapZoom = map.getZoom();

      $(".mapkey-table-entry").each(function () {
        var data = $(this).data();

        if (mapLayer == data.layer && mapZoom >= data.zoomMin && mapZoom <= data.zoomMax) {
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
