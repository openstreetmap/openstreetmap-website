L.Control.Zoomslider = L.Control.extend({
	options: {
		position: 'topleft',
		// height in px of zoom-slider.png
		stepHeight: 9
	},

	onAdd: function (map) {
		var className = 'leaflet-control-zoomslider',
				container = L.DomUtil.create('div', className);

		L.DomEvent
			.on(container, 'click', L.DomEvent.stopPropagation)
			.on(container, 'mousedown', L.DomEvent.stopPropagation)
			.on(container, 'dblclick', L.DomEvent.stopPropagation);
		
		this._map = map;

		this._zoomInButton = this._createButton('+', 'Zoom in', className + '-in'
												, container, this._zoomIn , this);
		this._createSlider(className + '-slider', container, map);
		this._zoomOutButton = this._createButton('-', 'Zoom out', className + '-out'
												 , container, this._zoomOut, this);
		
		map.on('layeradd layerremove', this._refresh, this);

		map.whenReady(function(){
			this._snapToSliderValue();
			map.on('zoomend', this._snapToSliderValue, this);
		}, this);

		return container;
	},

	onRemove: function(map){
		map.off('zoomend', this._snapToSliderValue);
		map.off('layeradd layerremove', this._refresh);
	},

	_refresh: function(){
		this._map
			.removeControl(this)
			.addControl(this);
	},

	_createSlider: function (className, container, map) {
		var zoomLevels = map.getMaxZoom() - map.getMinZoom();
		this._sliderHeight = this.options.stepHeight * zoomLevels;

		var wrapper =  L.DomUtil.create('div', className + '-wrap', container);
		wrapper.style.height = (this._sliderHeight + 5) + "px";
		var slider = L.DomUtil.create('div', className, wrapper);
		this._knob = L.DomUtil.create('div', className + '-knob', slider);

		this._draggable = this._createDraggable();
		this._draggable.enable();

		L.DomEvent.on(slider, 'click', this._onSliderClick, this);

		return slider;
	},

	_zoomIn: function (e) {
	    this._map.zoomIn(e.shiftKey ? 3 : 1);
	},

	_zoomOut: function (e) {
	    this._map.zoomOut(e.shiftKey ? 3 : 1);
	},

	_createButton: function (html, title, className, container, fn, context) {
		var link = L.DomUtil.create('a', className, container);
		link.innerHTML = html;
		link.href = '#';
		link.title = title;

		L.DomEvent
		    .on(link, 'click', L.DomEvent.preventDefault)
		    .on(link, 'click', fn, context);

		return link;
	},

	_createDraggable: function() {
		L.DomUtil.setPosition(this._knob, new L.Point(0, 0));
		L.DomEvent
			.on(this._knob
				, L.Draggable.START
				, L.DomEvent.stopPropagation)
			.on(this._knob, 'click', L.DomEvent.stopPropagation);

		var bounds = new L.Bounds(
			new L.Point(0, 0),
			new L.Point(0, this._sliderHeight)
		);
		var draggable = new L.BoundedDraggable(this._knob,
											   this._knob,
											   bounds)
			.on('drag', this._snap, this)
			.on('dragend', this._setZoom, this);

		return draggable;
	},

	_snap : function(){
		this._snapToSliderValue(this._posToSliderValue());
	},
	_setZoom: function() {
		this._map.setZoom(this._toZoomLevel(this._posToSliderValue()));
	},

	_onSliderClick: function(e){
		var first = (e.touches && e.touches.length === 1 ? e.touches[0] : e);
	    var offset = first.offsetY
			? first.offsetY
			: L.DomEvent.getMousePosition(first).y
			- L.DomUtil.getViewportOffset(this._knob).y;
		var value = this._posToSliderValue(offset - this._knob.offsetHeight / 2);
		this._snapToSliderValue(value);
		this._map.setZoom(this._toZoomLevel(value));
	},

	_posToSliderValue: function(pos) {
		pos = isNaN(pos)
			? L.DomUtil.getPosition(this._knob).y
			: pos;
		return Math.round( (this._sliderHeight - pos) / this.options.stepHeight);
	},

	_snapToSliderValue: function(sliderValue) {
		this._updateDisabled();
		if(this._knob) {
			sliderValue = isNaN(sliderValue)
				? this._getSliderValue()
				: sliderValue;
			var y = this._sliderHeight
				- (sliderValue * this.options.stepHeight);
			L.DomUtil.setPosition(this._knob, new L.Point(0, y));
		}
	},
	_toZoomLevel: function(sliderValue) {
		return sliderValue + this._map.getMinZoom();
	},
	_toSliderValue: function(zoomLevel) {
		return zoomLevel - this._map.getMinZoom();
	},
	_getSliderValue: function(){
		return this._toSliderValue(this._map.getZoom());
	},

	_updateDisabled: function () {
		var map = this._map,
			className = 'leaflet-control-zoomslider-disabled';

		L.DomUtil.removeClass(this._zoomInButton, className);
		L.DomUtil.removeClass(this._zoomOutButton, className);

		if (map.getZoom() === map.getMinZoom()) {
			L.DomUtil.addClass(this._zoomOutButton, className);
		}
		if (map.getZoom() === map.getMaxZoom()) {
			L.DomUtil.addClass(this._zoomInButton, className);
		}
	}
});

L.Map.mergeOptions({
    zoomControl: false,
    zoomsliderControl: true
});

L.Map.addInitHook(function () {
    if (this.options.zoomsliderControl) {
		L.control.zoomslider().addTo(this);
	}
});

L.control.zoomslider = function (options) {
    return new L.Control.Zoomslider(options);
};


L.BoundedDraggable = L.Draggable.extend({
	initialize: function(element, dragStartTarget, bounds) {
		L.Draggable.prototype.initialize.call(this, element, dragStartTarget);
		this._bounds = bounds;
		this.on('predrag', function() {
			if(!this._bounds.contains(this._newPos)){
				this._newPos = this._fitPoint(this._newPos);
			}
		}, this);
	},
	_fitPoint: function(point){
		var closest = new L.Point(
			Math.min(point.x, this._bounds.max.x),
			Math.min(point.y, this._bounds.max.y)
		);
		closest.x = Math.max(closest.x, this._bounds.min.x);
		closest.y = Math.max(closest.y, this._bounds.min.y);
		return closest;
	}
});
