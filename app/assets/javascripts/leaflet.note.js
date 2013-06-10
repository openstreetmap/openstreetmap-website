L.Control.Note = L.Control.extend({
    options: {
        position: 'topright',
        title: 'Notes',
    },

    onAdd: function (map) {
        var className = 'control-note',
            container = L.DomUtil.create('div', className);

        var link = L.DomUtil.create('a', 'control-button', container);
        link.innerHTML = "<span class='icon note'></span>";
        link.href = '#';
        link.title = this.options.title;

        L.DomEvent
            .on(link, 'click', L.DomEvent.stopPropagation)
            .on(link, 'click', L.DomEvent.preventDefault)
            .on(link, 'click', this._toggle, this)
            .on(link, 'dblclick', L.DomEvent.stopPropagation);

        this.map = map;

        return container;
    },

    // TODO: this relies on notesLayer on the map
    _toggle: function() {
        if (this.map.hasLayer(this.map.noteLayer)) {
            this.map.removeLayer(this.map.noteLayer);
        } else {
            this.map.addLayer(this.map.noteLayer);
        }
    }
});

L.control.note = function(options) {
    return new L.Control.Note(options);
};
