L.OSM.layers = function(options) {
  var control = L.control(options);

  control.onAdd = function (map) {
    var layers = options.layers;

    var $container = $('<div>')
      .attr('class', 'control-layers');

    var button = $('<a>')
      .attr('class', 'control-button')
      .attr('href', '#')
      .attr('title', 'Layers')
      .html('<span class="icon layers"></span>')
      .on('click', toggle)
      .appendTo($container);

    var $ui = $('<div>')
      .attr('class', 'layers-ui');

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
          .text(I18n.t('javascripts.map.layers.header')));

    var baseSection = $('<div>')
      .attr('class', 'section base-layers')
      .appendTo($ui);

    list = $('<ul>')
      .appendTo(baseSection);

    layers.forEach(function(layer) {
      var item = $('<li>')
        .appendTo(list);

      if (map.hasLayer(layer)) {
        item.addClass('active');
      }

      var div = $('<div>')
        .appendTo(item);

      map.whenReady(function() {
        var miniMap = L.map(div[0], {attributionControl: false, zoomControl: false})
          .addLayer(new layer.constructor());

        miniMap.dragging.disable();
        miniMap.touchZoom.disable();
        miniMap.doubleClickZoom.disable();
        miniMap.scrollWheelZoom.disable();

        $ui
          .on('show', shown)
          .on('hide', hide);

        function shown() {
          miniMap.invalidateSize();
          setView({animate: false});
          map.on('moveend', moved);
        }

        function hide() {
          map.off('moveend', moved);
        }

        function moved() {
          setView();
        }

        function setView(options) {
          miniMap.setView(map.getCenter(), Math.max(map.getZoom() - 2, 0), options);
        }
      });

      var label = $('<label>')
        .appendTo(item);

      var input = $('<input>')
        .attr('type', 'radio')
        .prop('checked', map.hasLayer(layer))
        .appendTo(label);

      label.append(layer.options.name);

      item.on('click', function() {
        layers.forEach(function(other) {
          if (other === layer) {
            map.addLayer(other);
          } else {
            map.removeLayer(other);
          }
        });
        map.fire('baselayerchange', {layer: layer});
      });

      map.on('layeradd layerremove', function() {
        item.toggleClass('active', map.hasLayer(layer));
        input.prop('checked', map.hasLayer(layer));
      });
    });

    if (OSM.STATUS != 'api_offline' && OSM.STATUS != 'database_offline') {
      var overlaySection = $('<div>')
        .attr('class', 'section overlay-layers')
        .appendTo($ui);

      $('<p>')
        .text(I18n.t('javascripts.map.layers.overlays'))
        .appendTo(overlaySection);

      var list = $('<ul>')
        .appendTo(overlaySection);

      function addOverlay(layer, name) {
        var item = $('<li>')
          .appendTo(list);

        var label = $('<label>')
          .appendTo(item);

        var input = $('<input>')
          .attr('type', 'checkbox')
          .prop('checked', map.hasLayer(layer))
          .appendTo(label);

        label.append(name);

        input.on('change', function() {
          if (input.is(':checked')) {
            map.addLayer(layer);
          } else {
            map.removeLayer(layer);
          }
        });

        map.on('layeradd layerremove', function() {
          input.prop('checked', map.hasLayer(layer));
        });
      }

      addOverlay(map.noteLayer, I18n.t('javascripts.map.layers.notes'));
      addOverlay(map.dataLayer, I18n.t('javascripts.map.layers.data'));
    }

    options.sidebar.addPane($ui);

    function toggle(e) {
      e.stopPropagation();
      e.preventDefault();
      options.sidebar.togglePane($ui, button);
    }

    return $container[0];
  };

  return control;
};
