//= require templates/map/share

L.Control.Share = L.Control.extend({
    options: {
        position: 'topright',
        title: 'Share'
    },

    onAdd: function (map) {
        var className = 'leaflet-control-locate',
            classNames = className + ' leaflet-control-zoom leaflet-bar leaflet-control',
            container = L.DomUtil.create('div', classNames);

        var self = this;
        this._layer = new L.LayerGroup();
        this._layer.addTo(map);
        this._event = undefined;

        var link = L.DomUtil.create('a', 'leaflet-bar-part leaflet-bar-part-single', container);
        link.href = '#';
        link.title = this.options.title;

        this._uiPane = L.DomUtil.create('div', 'leaflet-map-ui', map._container);

        L.DomEvent
            .on(link, 'click', L.DomEvent.stopPropagation)
            .on(link, 'click', L.DomEvent.preventDefault)
            .on(link, 'click', this.toggle, this)
            .on(link, 'dblclick', L.DomEvent.stopPropagation);

        return container;
    },

    toggle: function() {
        var controlContainer = $('.leaflet-control-container .leaflet-top.leaflet-right');

        if ($(this._uiPane).is(':visible')) {
            $(this._uiPane).hide();
            controlContainer.css({paddingRight: '0'});
        } else {
            $(this._uiPane)
                .show()
                .html(JST["templates/map/share"]());
            controlContainer.css({paddingRight: '200px'});
        }
    }
});

L.control.share = function(options) {
    return new L.Control.Share(options);
};
