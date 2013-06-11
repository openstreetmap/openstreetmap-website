//= require templates/map/layers

L.OSM.Layers = L.Control.extend({
  onAdd: function (map) {
    this._map = map;
    this._initLayout(map);
    return this._container;
  },

  _initLayout: function () {
    var className = 'leaflet-control-map-ui',
      container = this._container = L.DomUtil.create('div', className);

    var link = L.DomUtil.create('a', 'control-button', container);
    link.innerHTML = "<span class='icon layers'></span>";
    link.href = '#';
    link.title = 'Layers';

    this._ui = $(L.DomUtil.create('div', 'layers-ui', this.options.uiPane))
      .html(JST["templates/map/layers"]());

    var list = this._ui.find('.base-layers ul');

    this.options.layers.forEach(function(layer) {
      var item = $('<li></li>')
        .appendTo(list);

      if (this._map.hasLayer(layer)) {
        item.addClass('active');
      }

      var div = $('<div></div>')
        .appendTo(item);

      this._map.whenReady(function() {
        var map = L.map(div[0], {attributionControl: false, zoomControl: false})
          .setView(this._map.getCenter(), Math.max(this._map.getZoom() - 2, 0))
          .addLayer(new layer.constructor);

        map.dragging.disable();
        map.touchZoom.disable();
        map.doubleClickZoom.disable();
        map.scrollWheelZoom.disable();
      }, this);

      var label = $('<label></label>')
        .text(layer.options.name)
        .appendTo(item);

      item.on('click', function() {
        this.options.layers.forEach(function(other) {
          if (other === layer) {
            this._map.addLayer(other);
          } else {
            this._map.removeLayer(other);
          }
        }, this);
      }.bind(this));

      this._map.on('layeradd', function(e) {
        if (e.layer === layer) {
          item.addClass('active');
        }
      }).on('layerremove', function(e) {
        if (e.layer === layer) {
          item.removeClass('active');
        }
      });
    }, this);

    $(link).on('click', $.proxy(this.toggleLayers, this));
  },

  toggleLayers: function (e) {
    e.stopPropagation();
    e.preventDefault();

    var controlContainer = $('.leaflet-control-container .leaflet-top.leaflet-right');

    if ($(this._ui).is(':visible')) {
      $(this.options.uiPane).hide();
      controlContainer.css({paddingRight: '0'});
    } else {
      $(this.options.uiPane).show();
      controlContainer.css({paddingRight: '230px'});
    }
  }
});

L.OSM.layers = function(options) {
  return new L.OSM.Layers(options);
};
