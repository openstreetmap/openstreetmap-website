//= require templates/map/layers

OSM.MapUI = L.Control.extend({
    onAdd: function(map) {
        this._initLayout(map);
        return this._container;
    },

    _initLayout: function(map) {
        var className = 'leaflet-control-map-ui',
            container = this._container = L.DomUtil.create('div', className);

        var link = this._layersLink = L.DomUtil.create('a', 'leaflet-map-ui-layers', container);
        link.href = '#';
        link.title = 'Layers';

        this._uiPane = L.DomUtil.create('div', 'leaflet-map-ui', map._container);

        $(link).on('click', $.proxy(this.toggleLayers, this));
    },

    toggleLayers: function(e) {
        e.stopPropagation();
        e.preventDefault();

        if ($(this._uiPane).is(':visible')) {
            $(this._uiPane).hide();
            $(this._container).css({paddingRight: '0'})
        } else {
            $(this._uiPane)
                .show()
                .html(JST["templates/map/layers"]());
            $(this._container).css({paddingRight: '200px'})
        }
    }
});

OSM.mapUI = function() {
    return new OSM.MapUI();
};
