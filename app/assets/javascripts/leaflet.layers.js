//= require templates/map/layers

L.OSM.Layers = L.Control.extend({
  onAdd: function (map) {
    this._map = map;
    this._initLayout(map);
    return this._container;
  },

  _initLayout: function (map) {
    var className = 'leaflet-control-map-ui',
      container = this._container = L.DomUtil.create('div', className);

    var link = this._layersLink = L.DomUtil.create('a', 'leaflet-map-ui-layers', container);
    link.href = '#';
    link.title = 'Layers';

    this._uiPane = this.options.uiPane;

    $(link).on('click', $.proxy(this.toggleLayers, this));
  },

  toggleLayers: function (e) {
    e.stopPropagation();
    e.preventDefault();

    var controlContainer = $('.leaflet-control-container .leaflet-top.leaflet-right');

    if ($(this._uiPane).is(':visible')) {
      $(this._uiPane).hide();
      controlContainer.css({paddingRight: '0'});
    } else {
      $(this._uiPane)
        .show()
        .html(JST["templates/map/layers"]());

      var list = $(this._uiPane).find('.base-layers ul');

      var layers = this.options.layers;
      for (var i = 0; i < layers.length; i++) {
        var item = $('<li></li>')
          .appendTo(list);

        var div = $('<div></div>')
            .appendTo(item);

        var map = L.map(div[0], {attributionControl: false, zoomControl: false})
          .setView(this._map.getCenter(), Math.max(this._map.getZoom() - 2, 0))
          .addLayer(new layers[i].layer.constructor);

        map.dragging.disable();
        map.touchZoom.disable();
        map.doubleClickZoom.disable();
        map.scrollWheelZoom.disable();

        var label = $('<label></label>')
          .text(layers[i].name)
          .appendTo(item);
      }

      controlContainer.css({paddingRight: '200px'});
    }
  }
});

L.OSM.layers = function(options) {
  return new L.OSM.Layers(options);
};
