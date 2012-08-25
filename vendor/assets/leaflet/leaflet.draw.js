/*
 Copyright (c) 2012, Smartrak, Jacob Toye
 Leaflet.draw is an open-source JavaScript library for drawing shapes/markers on leaflet powered maps.
 https://github.com/jacobtoye/Leaflet.draw
*/
(function (window, undefined) {

L.drawVersion = '0.1.4';

L.Util.extend(L.LineUtil, {
	// Checks to see if two line segments intersect. Does not handle degenerate cases.
	// http://compgeom.cs.uiuc.edu/~jeffe/teaching/373/notes/x06-sweepline.pdf
	segmentsIntersect: function (/*Point*/ p, /*Point*/ p1, /*Point*/ p2, /*Point*/ p3) {
		return	this._checkCounterclockwise(p, p2, p3) !==
				this._checkCounterclockwise(p1, p2, p3) &&
				this._checkCounterclockwise(p, p1, p2) !==
				this._checkCounterclockwise(p, p1, p3);
	},

	// check to see if points are in counterclockwise order
	_checkCounterclockwise: function (/*Point*/ p, /*Point*/ p1, /*Point*/ p2) {
		return (p2.y - p.y) * (p1.x - p.x) > (p1.y - p.y) * (p2.x - p.x);
	}
});

L.Polyline.include({
	// Check to see if this polyline has any linesegments that intersect.
	// NOTE: does not support detecting intersection for degenerate cases.
	intersects: function () {
		var points = this._originalPoints,
			len = points ? points.length : 0,
			i, j, p, p1, p2, p3;

		if (this._tooFewPointsForIntersection()) {
			return false;
		}

		for (i = len - 1; i >= 3; i--) {
			p = points[i - 1];
			p1 = points[i];

			
			if (this._lineSegmentsIntersectsRange(p, p1, i - 2)) {
				return true;
			}
		}

		return false;
	},

	// Check for intersection if new latlng was added to this polyline.
	// NOTE: does not support detecting intersection for degenerate cases.
	newLatLngIntersects: function (latlng, skipFirst) {
		// Cannot check a polyline for intersecting lats/lngs when not added to the map
		if (!this._map) {
			return false;
		}

		return this.newPointIntersects(this._map.latLngToLayerPoint(latlng), skipFirst);
	},

	// Check for intersection if new point was added to this polyline.
	// newPoint must be a layer point.
	// NOTE: does not support detecting intersection for degenerate cases.
	newPointIntersects: function (newPoint, skipFirst) {
		var points = this._originalPoints,
			len = points ? points.length : 0,
			lastPoint = points ? points[len - 1] : null,
			// The previous previous line segment. Previous line segement doesn't need testing.
			maxIndex = len - 2;

		if (this._tooFewPointsForIntersection(1)) {
			return false;
		}

		return this._lineSegmentsIntersectsRange(lastPoint, newPoint, maxIndex, skipFirst ? 1 : 0);
	},

	// Polylines with 2 sides can only intersect in cases where points are collinear (we don't support detecting these).
	// Cannot have intersection when < 3 line segments (< 4 points)
	_tooFewPointsForIntersection: function (extraPoints) {
		var points = this._originalPoints,
			len = points ? points.length : 0;
		// Increment length by extraPoints if present
		len += extraPoints || 0;

		return !this._originalPoints || len <= 3;
	},

	// Checks a line segment intersections with any line segements before its predecessor.
	// Don't need to check the predecessor as will never intersect.
	_lineSegmentsIntersectsRange: function (p, p1, maxIndex, minIndex) {
		var points = this._originalPoints,
			p2, p3;

		minIndex = minIndex || 0;

		// Check all previous line segments (beside the immediately previous) for intersections
		for (var j = maxIndex; j > minIndex; j--) {
			p2 = points[j - 1];
			p3 = points[j];

			if (L.LineUtil.segmentsIntersect(p, p1, p2, p3)) {
				return true;
			}
		}

		return false;
	}
});

L.Polygon.include({
	// Checks a polygon for any intersecting line segments. Ignores holes.
	intersects: function () {
		var polylineIntersects,
			points = this._originalPoints,
			len, firstPoint, lastPoint, maxIndex;

		if (this._tooFewPointsForIntersection()) {
			return false;
		}

		polylineIntersects = L.Polyline.prototype.intersects.call(this);

		// If already found an intersection don't need to check for any more.
		if (polylineIntersects) {
			return true;
		}

		len = points.length;
		firstPoint = points[0];
		lastPoint = points[len - 1];
		maxIndex = len - 2;

		// Check the line segment between last and first point. Don't need to check the first line segment (minIndex = 1)
		return this._lineSegmentsIntersectsRange(lastPoint, firstPoint, maxIndex, 1);
	}
});

L.Handler.Draw = L.Handler.extend({
	includes: L.Mixin.Events,

	initialize: function (map, options) {
		this._map = map;
		this._container = map._container;
		this._overlayPane = map._panes.overlayPane;
		this._popupPane = map._panes.popupPane;

		// Merge default shapeOptions options with custom shapeOptions
		if (options && options.shapeOptions) {
			options.shapeOptions = L.Util.extend({}, this.options.shapeOptions, options.shapeOptions);
		}
		L.Util.extend(this.options, options);
	},

	enable: function () {
		this.fire('activated');
		L.Handler.prototype.enable.call(this);
	},
	
	addHooks: function () {
		if (this._map) {
			L.DomUtil.disableTextSelection();

			this._label = L.DomUtil.create('div', 'leaflet-draw-label', this._popupPane);
			this._singleLineLabel = false;

			L.DomEvent.addListener(this._container, 'keyup', this._cancelDrawing, this);
		}
	},

	removeHooks: function () {
		if (this._map) {
			L.DomUtil.enableTextSelection();

			this._popupPane.removeChild(this._label);
			delete this._label;

			L.DomEvent.removeListener(this._container, 'keyup', this._cancelDrawing);
		}
	},

	_updateLabelText: function (labelText) {
		labelText.subtext = labelText.subtext || '';

		// update the vertical position (only if changed)
		if (labelText.subtext.length === 0 && !this._singleLineLabel) {
			L.DomUtil.addClass(this._label, 'leaflet-draw-label-single');
			this._singleLineLabel = true;
		}
		else if (labelText.subtext.length > 0 && this._singleLineLabel) {
			L.DomUtil.removeClass(this._label, 'leaflet-draw-label-single');
			this._singleLineLabel = false;
		}

		this._label.innerHTML =
			(labelText.subtext.length > 0 ? '<span class="leaflet-draw-label-subtext">' + labelText.subtext + '</span>' + '<br />' : '') +
			'<span>' + labelText.text + '</span>';
	},

	_updateLabelPosition: function (pos) {
		L.DomUtil.setPosition(this._label, pos);
	},

	// Cancel drawing when the escape key is pressed
	_cancelDrawing: function (e) {
		if (e.keyCode === 27) {
			this.disable();
		}
	}
});

L.Polyline.Draw = L.Handler.Draw.extend({
	Poly: L.Polyline,

	options: {
		allowIntersection: true,
		drawError: {
			color: '#b00b00',
			message: '<strong>Error:</strong> shape edges cannot cross!',
			timeout: 2500
		},
		icon: new L.DivIcon({
			iconSize: new L.Point(8, 8),
			className: 'leaflet-div-icon leaflet-editing-icon'
		}),
		guidelineDistance: 20,
		shapeOptions: {
			stroke: true,
			color: '#f06eaa',
			weight: 4,
			opacity: 0.5,
			fill: false,
			clickable: true
		},
		zIndexOffset: 2000 // This should be > than the highest z-index any map layers
	},

	initialize: function (map, options) {
		// Merge default drawError options with custom options
		if (options && options.drawError) {
			options.drawError = L.Util.extend({}, this.options.drawError, options.drawError);
		}
		L.Handler.Draw.prototype.initialize.call(this, map, options);
	},
	
	addHooks: function () {
		L.Handler.Draw.prototype.addHooks.call(this);
		if (this._map) {
			this._markers = [];

			this._markerGroup = new L.LayerGroup();
			this._map.addLayer(this._markerGroup);

			this._poly = new L.Polyline([], this.options.shapeOptions);

			this._updateLabelText(this._getLabelText());

			// Make a transparent marker that will used to catch click events. These click
			// events will create the vertices. We need to do this so we can ensure that
			// we can create vertices over other map layers (markers, vector layers). We
			// also do not want to trigger any click handlers of objects we are clicking on
			// while drawing.
			if (!this._mouseMarker) {
				this._mouseMarker = L.marker(this._map.getCenter(), {
					icon: L.divIcon({
						className: 'leaflet-mouse-marker',
						iconAnchor: [20, 20],
						iconSize: [40, 40]
					}),
					opacity: 0,
					zIndexOffset: this.options.zIndexOffset
				});
			}

			this._mouseMarker
				.on('click', this._onClick, this)
				.addTo(this._map);

			this._map.on('mousemove', this._onMouseMove, this);
		}
	},

	removeHooks: function () {
		L.Handler.Draw.prototype.removeHooks.call(this);

		this._clearHideErrorTimeout();

		this._cleanUpShape();
		
		// remove markers from map
		this._map.removeLayer(this._markerGroup);
		delete this._markerGroup;
		delete this._markers;

		this._map.removeLayer(this._poly);
		delete this._poly;

		this._mouseMarker.off('click', this._onClick);
		this._map.removeLayer(this._mouseMarker);
		delete this._mouseMarker;

		// clean up DOM
		this._clearGuides();

		this._map.off('mousemove', this._onMouseMove);
	},

	_finishShape: function () {
		if (!this.options.allowIntersection && this._poly.newLatLngIntersects(this._poly.getLatLngs()[0], true)) {
			this._showErrorLabel();
			return;
		}
		if (!this._shapeIsValid()) {
			this._showErrorLabel();
			return;
		}

		this._map.fire(
			'draw:poly-created',
			{ poly: new this.Poly(this._poly.getLatLngs(), this.options.shapeOptions) }
		);
		this.disable();
	},

	//Called to verify the shape is valid when the user tries to finish it
	//Return false if the shape is not valid
	_shapeIsValid: function () {
		return true;
	},

	_onMouseMove: function (e) {
		var newPos = e.layerPoint,
			latlng = e.latlng,
			markerCount = this._markers.length;

		// Save latlng
		this._currentLatLng = latlng;

		// update the label
		this._updateLabelPosition(newPos);

		if (markerCount > 0) {
			this._updateLabelText(this._getLabelText());
			// draw the guide line
			this._clearGuides();
			this._drawGuide(
				this._map.latLngToLayerPoint(this._markers[markerCount - 1].getLatLng()),
				newPos
			);
		}

		// Update the mouse marker position
		this._mouseMarker.setLatLng(latlng);

		L.DomEvent.preventDefault(e.originalEvent);
	},

	_onClick: function (e) {
		var latlng = e.target.getLatLng(),
			markerCount = this._markers.length;

		if (markerCount > 0 && !this.options.allowIntersection && this._poly.newLatLngIntersects(latlng)) {
			this._showErrorLabel();
			return;
		}
		else if (this._errorShown) {
			this._hideErrorLabel();
		}

		this._markers.push(this._createMarker(latlng));

		this._poly.addLatLng(latlng);

		if (this._poly.getLatLngs().length === 2) {
			this._map.addLayer(this._poly);
		}

		this._updateMarkerHandler();

		this._vertexAdded(latlng);
	},

	_updateMarkerHandler: function () {
		// The last marker shold have a click handler to close the polyline
		if (this._markers.length > 1) {
			this._markers[this._markers.length - 1].on('click', this._finishShape, this);
		}
		
		// Remove the old marker click handler (as only the last point should close the polyline)
		if (this._markers.length > 2) {
			this._markers[this._markers.length - 2].off('click', this._finishShape);
		}
	},
	
	_createMarker: function (latlng) {
		var marker = new L.Marker(latlng, {
			icon: this.options.icon,
			zIndexOffset: this.options.zIndexOffset * 2
		});
		
		this._markerGroup.addLayer(marker);

		return marker;
	},

	_drawGuide: function (pointA, pointB) {
		var length = Math.floor(Math.sqrt(Math.pow((pointB.x - pointA.x), 2) + Math.pow((pointB.y - pointA.y), 2))),
			i,
			fraction,
			dashPoint,
			dash;

		//create the guides container if we haven't yet (TODO: probaly shouldn't do this every time the user starts to draw?)
		if (!this._guidesContainer) {
			this._guidesContainer = L.DomUtil.create('div', 'leaflet-draw-guides', this._overlayPane);
		}
	
		//draw a dash every GuildeLineDistance
		for (i = this.options.guidelineDistance; i < length; i += this.options.guidelineDistance) {
			//work out fraction along line we are
			fraction = i / length;

			//calculate new x,y point
			dashPoint = {
				x: Math.floor((pointA.x * (1 - fraction)) + (fraction * pointB.x)),
				y: Math.floor((pointA.y * (1 - fraction)) + (fraction * pointB.y))
			};

			//add guide dash to guide container
			dash = L.DomUtil.create('div', 'leaflet-draw-guide-dash', this._guidesContainer);
			dash.style.backgroundColor =
				!this._errorShown ? this.options.shapeOptions.color : this.options.drawError.color;

			L.DomUtil.setPosition(dash, dashPoint);
		}
	},

	_updateGuideColor: function (color) {
		if (this._guidesContainer) {
			for (var i = 0, l = this._guidesContainer.childNodes.length; i < l; i++) {
				this._guidesContainer.childNodes[i].style.backgroundColor = color;
			}
		}
	},

	// removes all child elements (guide dashes) from the guides container
	_clearGuides: function () {
		if (this._guidesContainer) {
			while (this._guidesContainer.firstChild) {
				this._guidesContainer.removeChild(this._guidesContainer.firstChild);
			}
		}
	},

	_updateLabelText: function (labelText) {
		if (!this._errorShown) {
			L.Handler.Draw.prototype._updateLabelText.call(this, labelText);
		}
	},

	_getLabelText: function () {
		var labelText,
			distance,
			distanceStr;

		if (this._markers.length === 0) {
			labelText = {
				text: 'Click to start drawing line.'
			};
		} else {
			// calculate the distance from the last fixed point to the mouse position
			distance = this._measurementRunningTotal + this._currentLatLng.distanceTo(this._markers[this._markers.length - 1].getLatLng());
			// show metres when distance is < 1km, then show km
			distanceStr = distance  > 1000 ? (distance  / 1000).toFixed(2) + ' km' : Math.ceil(distance) + ' m';
			
			if (this._markers.length === 1) {
				labelText = {
					text: 'Click to continue drawing line.',
					subtext: distanceStr
				};
			} else {
				labelText = {
					text: 'Click last point to finish line.',
					subtext: distanceStr
				};
			}
		}
		return labelText;
	},

	_showErrorLabel: function () {
		this._errorShown = true;

		// Update label
		L.DomUtil.addClass(this._label, 'leaflet-error-draw-label');
		L.DomUtil.addClass(this._label, 'leaflet-flash-anim');
		L.Handler.Draw.prototype._updateLabelText.call(this, { text: this.options.drawError.message });

		// Update shape
		this._updateGuideColor(this.options.drawError.color);
		this._poly.setStyle({ color: this.options.drawError.color });

		// Hide the error after 2 seconds
		this._clearHideErrorTimeout();
		this._hideErrorTimeout = setTimeout(L.Util.bind(this._hideErrorLabel, this), this.options.drawError.timeout);
	},

	_hideErrorLabel: function () {
		this._errorShown = false;

		this._clearHideErrorTimeout();
		
		// Revert label
		L.DomUtil.removeClass(this._label, 'leaflet-error-draw-label');
		L.DomUtil.removeClass(this._label, 'leaflet-flash-anim');
		this._updateLabelText(this._getLabelText());

		// Revert shape
		this._updateGuideColor(this.options.shapeOptions.color);
		this._poly.setStyle({ color: this.options.shapeOptions.color });
	},

	_clearHideErrorTimeout: function () {
		if (this._hideErrorTimeout) {
			clearTimeout(this._hideErrorTimeout);
			this._hideErrorTimeout = null;
		}
	},

	_vertexAdded: function (latlng) {
		if (this._markers.length === 1) {
			this._measurementRunningTotal = 0;
		}
		else {
			this._measurementRunningTotal +=
				latlng.distanceTo(this._markers[this._markers.length - 2].getLatLng());
		}
	},

	_cleanUpShape: function () {
		if (this._markers.length > 0) {
			this._markers[this._markers.length - 1].off('click', this._finishShape);
		}
	}
});

L.Polygon.Draw = L.Polyline.Draw.extend({
	Poly: L.Polygon,

	options: {
		shapeOptions: {
			stroke: true,
			color: '#f06eaa',
			weight: 4,
			opacity: 0.5,
			fill: true,
			fillColor: null, //same as color by default
			fillOpacity: 0.2,
			clickable: false
		}
	},

	_updateMarkerHandler: function () {
		// The first marker shold have a click handler to close the polygon
		if (this._markers.length === 1) {
			this._markers[0].on('click', this._finishShape, this);
		}
	},

	_getLabelText: function () {
		var text;
		if (this._markers.length === 0) {
			text = 'Click to start drawing shape.';
		} else if (this._markers.length < 3) {
			text = 'Click to continue drawing shape.';
		} else {
			text = 'Click first point to close this shape.';
		}
		return {
			text: text
		};
	},

	_shapeIsValid: function () {
		return this._markers.length >= 3;
	},

	_vertexAdded: function (latlng) {
		//calc area here
	},

	_cleanUpShape: function () {
		if (this._markers.length > 0) {
			this._markers[0].off('click', this._finishShape);
		}
	}
});

L.SimpleShape = {};

L.SimpleShape.Draw = L.Handler.Draw.extend({
	addHooks: function () {
		L.Handler.Draw.prototype.addHooks.call(this);
		if (this._map) {
			this._map.dragging.disable();
			//TODO refactor: move cursor to styles
			this._container.style.cursor = 'crosshair';

			this._updateLabelText({ text: this._initialLabelText });

			this._map
				.on('mousedown', this._onMouseDown, this)
				.on('mousemove', this._onMouseMove, this);

		}
	},

	removeHooks: function () {
		L.Handler.Draw.prototype.removeHooks.call(this);
		if (this._map) {
			this._map.dragging.enable();
			//TODO refactor: move cursor to styles
			this._container.style.cursor = '';

			this._map
				.off('mousedown', this._onMouseDown, this)
				.off('mousemove', this._onMouseMove, this);

			L.DomEvent.off(document, 'mouseup', this._onMouseUp);

			// If the box element doesn't exist they must not have moved the mouse, so don't need to destroy/return
			if (this._shape) {
				this._map.removeLayer(this._shape);
				delete this._shape;
			}
		}
		this._isDrawing = false;
	},

	_onMouseDown: function (e) {
		this._isDrawing = true;
		this._startLatLng = e.latlng;

		L.DomEvent
			.on(document, 'mouseup', this._onMouseUp, this)
			.preventDefault(e.originalEvent);
	},

	_onMouseMove: function (e) {
		var layerPoint = e.layerPoint,
				latlng = e.latlng;

		this._updateLabelPosition(layerPoint);
		if (this._isDrawing) {
			this._updateLabelText({ text: 'Release mouse to finish drawing.' });
			this._drawShape(latlng);
		}
	},

	_onMouseUp: function (e) {
		if (this._shape) {
			this._fireCreatedEvent();
		}
		
		this.disable();
	}
});

L.Circle.Draw = L.SimpleShape.Draw.extend({
	options: {
		shapeOptions: {
			stroke: true,
			color: '#f06eaa',
			weight: 4,
			opacity: 0.5,
			fill: true,
			fillColor: null, //same as color by default
			fillOpacity: 0.2,
			clickable: true
		}
	},

	_initialLabelText: 'Click and drag to draw circle.',

	_drawShape: function (latlng) {
		if (!this._shape) {
			this._shape = new L.Circle(this._startLatLng, this._startLatLng.distanceTo(latlng), this.options.shapeOptions);
			this._map.addLayer(this._shape);
		} else {
			this._shape.setRadius(this._startLatLng.distanceTo(latlng));
		}
	},

	_fireCreatedEvent: function () {
		this._map.fire(
			'draw:circle-created',
			{ circ: new L.Circle(this._startLatLng, this._shape.getRadius(), this.options.shapeOptions) }
		);
	}
});

L.Rectangle.Draw = L.SimpleShape.Draw.extend({
	options: {
		shapeOptions: {
			stroke: true,
			color: '#f06eaa',
			weight: 4,
			opacity: 0.5,
			fill: true,
			fillColor: null, //same as color by default
			fillOpacity: 0.2,
			clickable: true
		}
	},
	
	_initialLabelText: 'Click and drag to draw rectangle.',

	_drawShape: function (latlng) {
		if (!this._shape) {
			this._shape = new L.Rectangle(new L.LatLngBounds(this._startLatLng, latlng), this.options.shapeOptions);
			this._map.addLayer(this._shape);
		} else {
			this._shape.setBounds(new L.LatLngBounds(this._startLatLng, latlng));
		}
	},

	_fireCreatedEvent: function () {
		this._map.fire(
			'draw:rectangle-created',
			{ rect: new L.Rectangle(this._shape.getBounds(), this.options.shapeOptions) }
		);
	}
});

L.Marker.Draw = L.Handler.Draw.extend({
	options: {
		icon: new L.Icon.Default(),
		zIndexOffset: 2000 // This should be > than the highest z-index any markers
	},
	
	addHooks: function () {
		L.Handler.Draw.prototype.addHooks.call(this);
		
		if (this._map) {
			this._updateLabelText({ text: 'Click map to place marker.' });
			this._map.on('mousemove', this._onMouseMove, this);
		}
	},

	removeHooks: function () {
		L.Handler.Draw.prototype.removeHooks.call(this);
		
		if (this._map) {
			if (this._marker) {
				this._marker.off('click', this._onClick);
				this._map
					.off('click', this._onClick)
					.removeLayer(this._marker);
				delete this._marker;
			}

			this._map.off('mousemove', this._onMouseMove);
		}
	},

	_onMouseMove: function (e) {
		var newPos = e.layerPoint,
			latlng = e.latlng;

		this._updateLabelPosition(newPos);

		if (!this._marker) {
			this._marker = new L.Marker(latlng, {
				icon: this.options.icon,
				zIndexOffset: this.options.zIndexOffset
			});
			// Bind to both marker and map to make sure we get the click event.
			this._marker.on('click', this._onClick, this);
			this._map
				.on('click', this._onClick, this)
				.addLayer(this._marker);
		}
		else {
			this._marker.setLatLng(latlng);
		}
	},

	_onClick: function (e) {
		this._map.fire(
			'draw:marker-created',
			{ marker: new L.Marker(this._marker.getLatLng(), { icon: this.options.icon }) }
		);
		this.disable();
	}
});

L.Map.mergeOptions({
	drawControl: false
});

L.Control.Draw = L.Control.extend({

	options: {
		position: 'topleft',
		polyline: {
			title: 'Draw a polyline'
		},
		polygon: {
			title: 'Draw a polygon'
		},
		rectangle: {
			title: 'Draw a rectangle'
		},
		circle: {
			title: 'Draw a circle'
		},
		marker: {
			title: 'Add a marker'
		}
	},

	handlers: {},
	
	initialize: function (options) {
		L.Util.extend(this.options, options);
	},
	
	onAdd: function (map) {
		var className = 'leaflet-control-draw',
			container = L.DomUtil.create('div', className);

		if (this.options.polyline) {
			this.handlers.polyline = new L.Polyline.Draw(map, this.options.polyline);
			this._createButton(
				this.options.polyline.title,
				className + '-polyline',
				container,
				this.handlers.polyline.enable,
				this.handlers.polyline
			);
			this.handlers.polyline.on('activated', this._disableInactiveModes, this);
		}

		if (this.options.polygon) {
			this.handlers.polygon = new L.Polygon.Draw(map, this.options.polygon);
			this._createButton(
				this.options.polygon.title,
				className + '-polygon',
				container,
				this.handlers.polygon.enable,
				this.handlers.polygon
			);
			this.handlers.polygon.on('activated', this._disableInactiveModes, this);
		}

		if (this.options.rectangle) {
			this.handlers.rectangle = new L.Rectangle.Draw(map, this.options.rectangle);
			this._createButton(
				this.options.rectangle.title,
				className + '-rectangle',
				container,
				this.handlers.rectangle.enable,
				this.handlers.rectangle
			);
			this.handlers.rectangle.on('activated', this._disableInactiveModes, this);
		}

		if (this.options.circle) {
			this.handlers.circle = new L.Circle.Draw(map, this.options.circle);
			this._createButton(
				this.options.circle.title,
				className + '-circle',
				container,
				this.handlers.circle.enable,
				this.handlers.circle
			);
			this.handlers.circle.on('activated', this._disableInactiveModes, this);
		}

		if (this.options.marker) {
			this.handlers.marker = new L.Marker.Draw(map, this.options.marker);
			this._createButton(
				this.options.marker.title,
				className + '-marker',
				container,
				this.handlers.marker.enable,
				this.handlers.marker
			);
			this.handlers.marker.on('activated', this._disableInactiveModes, this);
		}
		
		return container;
	},

	_createButton: function (title, className, container, fn, context) {
		var link = L.DomUtil.create('a', className, container);
		link.href = '#';
		link.title = title;

		L.DomEvent
			.on(link, 'click', L.DomEvent.stopPropagation)
			.on(link, 'mousedown', L.DomEvent.stopPropagation)
			.on(link, 'dblclick', L.DomEvent.stopPropagation)
			.on(link, 'click', L.DomEvent.preventDefault)
			.on(link, 'click', fn, context);

		return link;
	},

	// Need to disable the drawing modes if user clicks on another without disabling the current mode
	_disableInactiveModes: function () {
		for (var i in this.handlers) {
			// Check if is a property of this object and is enabled
			if (this.handlers.hasOwnProperty(i) && this.handlers[i].enabled()) {
				this.handlers[i].disable();
			}
		}
	}
});

L.Map.addInitHook(function () {
	if (this.options.drawControl) {
		this.drawControl = new L.Control.Draw();
		this.addControl(this.drawControl);
	}
});



}(this));