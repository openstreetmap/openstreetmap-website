L.OSM.Layers = L.Control.extend({
  onAdd: function (map) {
    this._map = map;
    this._initLayout();
    return this.$container[0];
  },

  _initLayout: function () {
    var map = this._map,
      layers = this.options.layers;

    this.$container = $('<div>')
      .attr('class', 'control-layers');

    var link = $('<a>')
      .attr('class', 'control-button')
      .attr('href', '#')
      .attr('title', 'Layers')
      .html('<span class="icon layers"></span>')
      .appendTo(this.$container);

    if (OSM.STATUS != 'api_offline' && OSM.STATUS != 'database_offline') {
      this.$ui = $('<div>')
        .attr('class', 'layers-ui')
        .appendTo(this.options.uiPane);

      $('<h2>')
        .text(I18n.t('javascripts.map.layers.header'))
        .appendTo(this.$ui);

      var overlaySection = $('<section>')
        .addClass('overlay-layers')
        .appendTo(this.$ui);

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

    var baseSection = $('<section>')
      .addClass('base-layers')
      .appendTo(this.$ui);

    $('<p>')
      .text(I18n.t('javascripts.map.layers.base'))
      .appendTo(baseSection);

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
          .setView(map.getCenter(), Math.max(map.getZoom() - 2, 0))
          .addLayer(new layer.constructor);

        miniMap.dragging.disable();
        miniMap.touchZoom.disable();
        miniMap.doubleClickZoom.disable();
        miniMap.scrollWheelZoom.disable();

        map.on('moveend', function() {
          miniMap.setView(map.getCenter(), Math.max(map.getZoom() - 2, 0));
        });

        div.data('map', miniMap);
      });

      var label = $('<label>')
        .text(layer.options.name)
        .appendTo(item);

      item.on('click', function() {
        layers.forEach(function(other) {
          if (other === layer) {
            map.addLayer(other);
          } else {
            map.removeLayer(other);
          }
        });
      });

      map.on('layeradd layerremove', function() {
        item.toggleClass('active', map.hasLayer(layer));
      });
    });

    $(link).on('click', $.proxy(this.toggleLayers, this));
  },

  toggleLayers: function (e) {
    e.stopPropagation();
    e.preventDefault();

    var controlContainer = $('.leaflet-control-container .leaflet-top.leaflet-right');

    if (this.$ui.is(':visible')) {
      $(this.options.uiPane).hide();
      controlContainer.css({paddingRight: '0'});
    } else {
      $(this.options.uiPane).show();
      controlContainer.css({paddingRight: '230px'});
    }

    this.$ui.find('.base-layers .leaflet-container').each(function() {
      $(this).data('map').invalidateSize();
    });
  }
});

L.OSM.layers = function(options) {
  return new L.OSM.Layers(options);
};
