L.Control.Share = L.Control.extend({
    options: {
        position: 'topright',
        title: 'Share',
        url: function(map) {
            return '';
        }
    },

    onAdd: function (map) {
        var className = 'control-share',
            container = L.DomUtil.create('div', className);

        var link = L.DomUtil.create('a', 'control-button', container);
        link.innerHTML = "<span class='icon share'></span>";
        link.href = '#';
        link.title = this.options.title;

        this._uiPane = this.options.uiPane;

        this._map = map;

        var h2 = L.DomUtil.create('h2', '', this._uiPane);
        h2.innerHTML = I18n.t('javascripts.share.title');

        this._linkInput = L.DomUtil.create('input', '', this._uiPane);

        L.DomEvent
            .on(link, 'click', L.DomEvent.stopPropagation)
            .on(link, 'click', L.DomEvent.preventDefault)
            .on(link, 'click', this._toggle, this)
            .on(link, 'dblclick', L.DomEvent.stopPropagation);

        map.on('moveend layeradd layerremove', this._update, this);

        return container;
    },

    _update: function (e) {
        var center = this._map.getCenter().wrap();
        var layers = getMapLayers(this._map);
        this._linkInput.value = this.options.getUrl(this._map);
    },

    _toggle: function() {
        var controlContainer = $('.leaflet-control-container .leaflet-top.leaflet-right');

        if ($(this._uiPane).is(':visible')) {
            $(this._uiPane).hide();
            controlContainer.css({paddingRight: '0'});
        } else {
            $(this._uiPane).show();
            controlContainer.css({paddingRight: '200px'});
        }
    }
});

L.control.share = function(options) {
    return new L.Control.Share(options);
};
