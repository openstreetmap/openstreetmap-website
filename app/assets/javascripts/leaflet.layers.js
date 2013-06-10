//= require templates/map/layers

L.OSM.Layers = L.Control.extend({
  onAdd: function (map) {
    this._initLayout(map);
    return this._container;
  },

  _initLayout: function (map) {
    var className = 'leaflet-control-map-ui',
      container = this._container = L.DomUtil.create('div', className);

    var link = this._layersLink = L.DomUtil.create('a', 'leaflet-map-ui-layers', container);
    link.href = '#';
    link.title = 'Layers';

    this._uiPane = L.DomUtil.create('div', 'leaflet-map-ui', map._container);

    L.DomEvent
      .on(this._uiPane, 'click', L.DomEvent.stopPropagation)
      .on(this._uiPane, 'click', L.DomEvent.preventDefault)
      .on(this._uiPane, 'dblclick', L.DomEvent.preventDefault);

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
        .html(JST["templates/map/layers"]({layers: this.options.layers}));
      controlContainer.css({paddingRight: '200px'});
    }
  }
});

L.OSM.layers = function(options) {
  return new L.OSM.Layers(options);
};
