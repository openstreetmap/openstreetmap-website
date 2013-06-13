L.OSM.Zoom = L.Control.extend({
	options: {
		position: 'topright'
	},

	onAdd: function (map) {
		var zoomName = 'zoom',
		    container = L.DomUtil.create('div', zoomName);

		this._map = map;

		this._zoomInButton  = this._createButton(
		        '', I18n.t('javascripts.map.zoom.in'),  zoomName + 'in',  container, this._zoomIn,  this);
		this._zoomOutButton = this._createButton(
		        '', I18n.t('javascripts.map.zoom.out'), zoomName + 'out', container, this._zoomOut, this);

		map.on('zoomend zoomlevelschange', this._updateDisabled, this);

		return container;
	},

	onRemove: function (map) {
		map.off('zoomend zoomlevelschange', this._updateDisabled, this);
	},

	_zoomIn: function (e) {
		this._map.zoomIn(e.shiftKey ? 3 : 1);
	},

	_zoomOut: function (e) {
		this._map.zoomOut(e.shiftKey ? 3 : 1);
	},

	_createButton: function (html, title, className, container, fn, context) {
		var link = L.DomUtil.create('a', 'control-button ' + className, container);
		link.innerHTML = html;
		link.href = '#';
		link.title = title;

		var sprite = L.DomUtil.create('span', 'icon ' + className, link);

		var stop = L.DomEvent.stopPropagation;

		L.DomEvent
		    .on(link, 'click', stop)
		    .on(link, 'mousedown', stop)
		    .on(link, 'dblclick', stop)
		    .on(link, 'click', L.DomEvent.preventDefault)
		    .on(link, 'click', fn, context);

		return link;
	},

	_updateDisabled: function () {
		var map = this._map,
			className = 'leaflet-disabled';

		L.DomUtil.removeClass(this._zoomInButton, className);
		L.DomUtil.removeClass(this._zoomOutButton, className);

		if (map._zoom === map.getMinZoom()) {
			L.DomUtil.addClass(this._zoomOutButton, className);
		}
		if (map._zoom === map.getMaxZoom()) {
			L.DomUtil.addClass(this._zoomInButton, className);
		}
	}
});

L.OSM.zoom = function (options) {
	return new L.OSM.Zoom(options);
};
