/*!
Copyright (c) 2016 Dominik Moritz

This file is part of the leaflet locate control. It is licensed under the MIT license.
You can find the project at: https://github.com/domoritz/leaflet-locatecontrol
*/
(function (factory, window) {
     // see https://github.com/Leaflet/Leaflet/blob/master/PLUGIN-GUIDE.md#module-loaders
     // for details on how to structure a leaflet plugin.

    // define an AMD module that relies on 'leaflet'
    if (typeof define === 'function' && define.amd) {
        define(['leaflet'], factory);

    // define a Common JS module that relies on 'leaflet'
    } else if (typeof exports === 'object') {
        if (typeof window !== 'undefined' && window.L) {
            module.exports = factory(L);
        } else {
            module.exports = factory(require('leaflet'));
        }
    }

    // attach your plugin to the global 'L' variable
    if (typeof window !== 'undefined' && window.L){
        window.L.Control.Locate = factory(L);
    }
} (function (L) {
    var LDomUtilApplyClassesMethod = function(method, element, classNames) {
        classNames = classNames.split(' ');
        classNames.forEach(function(className) {
            L.DomUtil[method].call(this, element, className);
        });
    };

    var addClasses = function(el, names) { LDomUtilApplyClassesMethod('addClass', el, names); };
    var removeClasses = function(el, names) { LDomUtilApplyClassesMethod('removeClass', el, names); };

    /**
     * Compatible with L.Circle but a true marker instead of a path
     */
    var LocationMarker = L.Marker.extend({
        initialize: function (latlng, options) {
            L.Util.setOptions(this, options);
            this._latlng = latlng;
            this.createIcon();
        },

        /**
         * Create a styled circle location marker
         */
        createIcon: function() {
            var opt = this.options;

            var style = '';

            if (opt.color !== undefined) {
                style += 'stroke:'+opt.color+';';
            }
            if (opt.weight !== undefined) {
                style += 'stroke-width:'+opt.weight+';';
            }
            if (opt.fillColor !== undefined) {
                style += 'fill:'+opt.fillColor+';';
            }
            if (opt.fillOpacity !== undefined) {
                style += 'fill-opacity:'+opt.fillOpacity+';';
            }
            if (opt.opacity !== undefined) {
                style += 'opacity:'+opt.opacity+';';
            }

            var icon = this._getIconSVG(opt, style);

            this._locationIcon = L.divIcon({
                className: icon.className,
                html: icon.svg,
                iconSize: [icon.w,icon.h],
            });

            this.setIcon(this._locationIcon);
        },

        /**
         * Return the raw svg for the shape
         *
         * Split so can be easily overridden
         */
        _getIconSVG: function(options, style) {
            var r = options.radius;
            var w = options.weight;
            var s = r + w;
            var s2 = s * 2;
            var svg = '<svg xmlns="http://www.w3.org/2000/svg" width="'+s2+'" height="'+s2+'" version="1.1" viewBox="-'+s+' -'+s+' '+s2+' '+s2+'">' +
            '<circle r="'+r+'" style="'+style+'" />' +
            '</svg>';
            return {
                className: 'leaflet-control-locate-location',
                svg: svg,
                w: s2,
                h: s2
            };
        },

        setStyle: function(style) {
            L.Util.setOptions(this, style);
            this.createIcon();
        }
    });

    var CompassMarker = LocationMarker.extend({
        initialize: function (latlng, heading, options) {
            L.Util.setOptions(this, options);
            this._latlng = latlng;
            this._heading = heading;
            this.createIcon();
        },

        setHeading: function(heading) {
            this._heading = heading;
        },

        /**
         * Create a styled arrow compass marker
         */
        _getIconSVG: function(options, style) {
            var r = options.radius;
            var w = (options.width + options.weight);
            var h = (r+options.depth + options.weight)*2;
            var path = 'M0,0 l'+(options.width/2)+','+options.depth+' l-'+(w)+',0 z';
            var svgstyle = 'transform: rotate('+this._heading+'deg)';
            var svg = '<svg xmlns="http://www.w3.org/2000/svg" width="'+(w)+'" height="'+h+'" version="1.1" viewBox="-'+(w/2)+' 0 '+w+' '+h+'" style="'+svgstyle+'">'+
            '<path d="'+path+'" style="'+style+'" />'+
            '</svg>';
            return {
                className: 'leaflet-control-locate-heading',
                svg: svg,
                w: w,
                h: h
            };
        },
    });


    var LocateControl = L.Control.extend({
        options: {
            /** Position of the control */
            position: 'topleft',
            /** The layer that the user's location should be drawn on. By default creates a new layer. */
            layer: undefined,
            /**
             * Automatically sets the map view (zoom and pan) to the user's location as it updates.
             * While the map is following the user's location, the control is in the `following` state,
             * which changes the style of the control and the circle marker.
             *
             * Possible values:
             *  - false: never updates the map view when location changes.
             *  - 'once': set the view when the location is first determined
             *  - 'always': always updates the map view when location changes.
             *              The map view follows the user's location.
             *  - 'untilPan': like 'always', except stops updating the
             *                view if the user has manually panned the map.
             *                The map view follows the user's location until she pans.
             *  - 'untilPanOrZoom': (default) like 'always', except stops updating the
             *                view if the user has manually panned the map.
             *                The map view follows the user's location until she pans.
             */
            setView: 'untilPanOrZoom',
            /** Keep the current map zoom level when setting the view and only pan. */
            keepCurrentZoomLevel: false,
	    /** After activating the plugin by clicking on the icon, zoom to the selected zoom level, even when keepCurrentZoomLevel is true. Set to 'false' to disable this feature. */
	    initialZoomLevel: false,
            /**
             * This callback can be used to override the viewport tracking
             * This function should return a LatLngBounds object.
             *
             * For example to extend the viewport to ensure that a particular LatLng is visible:
             *
             * getLocationBounds: function(locationEvent) {
             *    return locationEvent.bounds.extend([-33.873085, 151.219273]);
             * },
             */
            getLocationBounds: function (locationEvent) {
                return locationEvent.bounds;
            },
            /** Smooth pan and zoom to the location of the marker. Only works in Leaflet 1.0+. */
            flyTo: false,
            /**
             * The user location can be inside and outside the current view when the user clicks on the
             * control that is already active. Both cases can be configures separately.
             * Possible values are:
             *  - 'setView': zoom and pan to the current location
             *  - 'stop': stop locating and remove the location marker
             */
            clickBehavior: {
                /** What should happen if the user clicks on the control while the location is within the current view. */
                inView: 'stop',
                /** What should happen if the user clicks on the control while the location is outside the current view. */
                outOfView: 'setView',
                /**
                 * What should happen if the user clicks on the control while the location is within the current view
                 * and we could be following but are not. Defaults to a special value which inherits from 'inView';
                 */
                inViewNotFollowing: 'inView',
            },
            /**
             * If set, save the map bounds just before centering to the user's
             * location. When control is disabled, set the view back to the
             * bounds that were saved.
             */
            returnToPrevBounds: false,
            /**
             * Keep a cache of the location after the user deactivates the control. If set to false, the user has to wait
             * until the locate API returns a new location before they see where they are again.
             */
            cacheLocation: true,
            /** If set, a circle that shows the location accuracy is drawn. */
            drawCircle: true,
            /** If set, the marker at the users' location is drawn. */
            drawMarker: true,
            /** If set and supported then show the compass heading */
            showCompass: true,
            /** The class to be used to create the marker. For example L.CircleMarker or L.Marker */
            markerClass: LocationMarker,
            /** The class us be used to create the compass bearing arrow */
            compassClass: CompassMarker,
            /** Accuracy circle style properties. NOTE these styles should match the css animations styles */
            circleStyle: {
                className:   'leaflet-control-locate-circle',
                color:       '#136AEC',
                fillColor:   '#136AEC',
                fillOpacity: 0.15,
                weight:      0
            },
            /** Inner marker style properties. Only works if your marker class supports `setStyle`. */
            markerStyle: {
                className:   'leaflet-control-locate-marker',
                color:       '#fff',
                fillColor:   '#2A93EE',
                fillOpacity: 1,
                weight:      3,
                opacity:     1,
                radius:      9
            },
            /** Compass */
            compassStyle: {
                fillColor:   '#2A93EE',
                fillOpacity: 1,
                weight:      0,
                color:       '#fff',
                opacity:     1,
                radius:      9, // How far is the arrow is from the center of of the marker
                width:       9, // Width of the arrow
                depth:       6  // Length of the arrow
            },
            /**
             * Changes to accuracy circle and inner marker while following.
             * It is only necessary to provide the properties that should change.
             */
            followCircleStyle: {},
            followMarkerStyle: {
                // color: '#FFA500',
                // fillColor: '#FFB000'
            },
            followCompassStyle: {},
            /** The CSS class for the icon. For example fa-location-arrow or fa-map-marker */
            icon: 'fa fa-map-marker',
            iconLoading: 'fa fa-spinner fa-spin',
            /** The element to be created for icons. For example span or i */
            iconElementTag: 'span',
            /** Padding around the accuracy circle. */
            circlePadding: [0, 0],
            /** Use metric units. */
            metric: true,
            /**
             * This callback can be used in case you would like to override button creation behavior.
             * This is useful for DOM manipulation frameworks such as angular etc.
             * This function should return an object with HtmlElement for the button (link property) and the icon (icon property).
             */
            createButtonCallback: function (container, options) {
                var link = L.DomUtil.create('a', 'leaflet-bar-part leaflet-bar-part-single', container);
                link.title = options.strings.title;
                var icon = L.DomUtil.create(options.iconElementTag, options.icon, link);
                return { link: link, icon: icon };
            },
            /** This event is called in case of any location error that is not a time out error. */
            onLocationError: function(err, control) {
                alert(err.message);
            },
            /**
             * This event is called when the user's location is outside the bounds set on the map.
             * The event is called repeatedly when the location changes.
             */
            onLocationOutsideMapBounds: function(control) {
                control.stop();
                alert(control.options.strings.outsideMapBoundsMsg);
            },
            /** Display a pop-up when the user click on the inner marker. */
            showPopup: true,
            strings: {
                title: "Show me where I am",
                metersUnit: "meters",
                feetUnit: "feet",
                popup: "You are within {distance} {unit} from this point",
                outsideMapBoundsMsg: "You seem located outside the boundaries of the map"
            },
            /** The default options passed to leaflets locate method. */
            locateOptions: {
                maxZoom: Infinity,
                watch: true,  // if you overwrite this, visualization cannot be updated
                setView: false // have to set this to false because we have to
                               // do setView manually
            }
        },

        initialize: function (options) {
            // set default options if nothing is set (merge one step deep)
            for (var i in options) {
                if (typeof this.options[i] === 'object') {
                    L.extend(this.options[i], options[i]);
                } else {
                    this.options[i] = options[i];
                }
            }

            // extend the follow marker style and circle from the normal style
            this.options.followMarkerStyle = L.extend({}, this.options.markerStyle, this.options.followMarkerStyle);
            this.options.followCircleStyle = L.extend({}, this.options.circleStyle, this.options.followCircleStyle);
            this.options.followCompassStyle = L.extend({}, this.options.compassStyle, this.options.followCompassStyle);
        },

        /**
         * Add control to map. Returns the container for the control.
         */
        onAdd: function (map) {
            var container = L.DomUtil.create('div',
                'leaflet-control-locate leaflet-bar leaflet-control');

            this._layer = this.options.layer || new L.LayerGroup();
            this._layer.addTo(map);
            this._event = undefined;
            this._compassHeading = null;
            this._prevBounds = null;

            var linkAndIcon = this.options.createButtonCallback(container, this.options);
            this._link = linkAndIcon.link;
            this._icon = linkAndIcon.icon;

            L.DomEvent
                .on(this._link, 'click', L.DomEvent.stopPropagation)
                .on(this._link, 'click', L.DomEvent.preventDefault)
                .on(this._link, 'click', this._onClick, this)
                .on(this._link, 'dblclick', L.DomEvent.stopPropagation);

            this._resetVariables();

            this._map.on('unload', this._unload, this);

            return container;
        },

        /**
         * This method is called when the user clicks on the control.
         */
        _onClick: function() {
            this._justClicked = true;
            var wasFollowing =  this._isFollowing();
            this._userPanned = false;
            this._userZoomed = false;

            if (this._active && !this._event) {
                // click while requesting
                this.stop();
            } else if (this._active && this._event !== undefined) {
                var behaviors = this.options.clickBehavior;
                var behavior = behaviors.outOfView;
                if (this._map.getBounds().contains(this._event.latlng)) {
                    behavior = wasFollowing ? behaviors.inView : behaviors.inViewNotFollowing;
                }

                // Allow inheriting from another behavior
                if (behaviors[behavior]) {
                    behavior = behaviors[behavior];
                }

                switch (behavior) {
                    case 'setView':
                        this.setView();
                        break;
                    case 'stop':
                        this.stop();
                        if (this.options.returnToPrevBounds) {
                            var f = this.options.flyTo ? this._map.flyToBounds : this._map.fitBounds;
                            f.bind(this._map)(this._prevBounds);
                        }
                        break;
                }
            } else {
                if (this.options.returnToPrevBounds) {
                  this._prevBounds = this._map.getBounds();
                }
                this.start();
            }

            this._updateContainerStyle();
        },

        /**
         * Starts the plugin:
         * - activates the engine
         * - draws the marker (if coordinates available)
         */
        start: function() {
            this._activate();

            if (this._event) {
                this._drawMarker(this._map);

                // if we already have a location but the user clicked on the control
                if (this.options.setView) {
                    this.setView();
                }
            }
            this._updateContainerStyle();
        },

        /**
         * Stops the plugin:
         * - deactivates the engine
         * - reinitializes the button
         * - removes the marker
         */
        stop: function() {
            this._deactivate();

            this._cleanClasses();
            this._resetVariables();

            this._removeMarker();
        },

        /**
         * Keep the control active but stop following the location
         */
        stopFollowing: function() {
            this._userPanned = true;
            this._updateContainerStyle();
            this._drawMarker();
        },

        /**
         * This method launches the location engine.
         * It is called before the marker is updated,
         * event if it does not mean that the event will be ready.
         *
         * Override it if you want to add more functionalities.
         * It should set the this._active to true and do nothing if
         * this._active is true.
         */
        _activate: function() {
            if (!this._active) {
                this._map.locate(this.options.locateOptions);
                this._active = true;

                // bind event listeners
                this._map.on('locationfound', this._onLocationFound, this);
                this._map.on('locationerror', this._onLocationError, this);
                this._map.on('dragstart', this._onDrag, this);
                this._map.on('zoomstart', this._onZoom, this);
                this._map.on('zoomend', this._onZoomEnd, this);
                if (this.options.showCompass) {
                    var oriAbs = 'ondeviceorientationabsolute' in window;
                    if (oriAbs || ('ondeviceorientation' in window)) {
                        var _this = this;
                        var deviceorientation = function () {
                            L.DomEvent.on(window, oriAbs ? 'deviceorientationabsolute' : 'deviceorientation', _this._onDeviceOrientation, _this);
                        };
                        if (DeviceOrientationEvent && typeof DeviceOrientationEvent.requestPermission === 'function') {
                            DeviceOrientationEvent.requestPermission().then(function (permissionState) {
                                if (permissionState === 'granted') {
                                    deviceorientation();
                                }
                            })
                        } else {
                            deviceorientation();
                        }
                    }
                }
            }
        },

        /**
         * Called to stop the location engine.
         *
         * Override it to shutdown any functionalities you added on start.
         */
        _deactivate: function() {
            this._map.stopLocate();
            this._active = false;

            if (!this.options.cacheLocation) {
                this._event = undefined;
            }

            // unbind event listeners
            this._map.off('locationfound', this._onLocationFound, this);
            this._map.off('locationerror', this._onLocationError, this);
            this._map.off('dragstart', this._onDrag, this);
            this._map.off('zoomstart', this._onZoom, this);
            this._map.off('zoomend', this._onZoomEnd, this);
            if (this.options.showCompass) {
                this._compassHeading = null;
                if ('ondeviceorientationabsolute' in window) {
                    L.DomEvent.off(window, 'deviceorientationabsolute', this._onDeviceOrientation, this);
                } else if ('ondeviceorientation' in window) {
                    L.DomEvent.off(window, 'deviceorientation', this._onDeviceOrientation, this);
                }
            }
        },

        /**
         * Zoom (unless we should keep the zoom level) and an to the current view.
         */
        setView: function() {
            this._drawMarker();
            if (this._isOutsideMapBounds()) {
                this._event = undefined;  // clear the current location so we can get back into the bounds
                this.options.onLocationOutsideMapBounds(this);
            } else {
		if (this._justClicked && this.options.initialZoomLevel !== false) {
                    var f = this.options.flyTo ? this._map.flyTo : this._map.setView;
                    f.bind(this._map)([this._event.latitude, this._event.longitude], this.options.initialZoomLevel);
		} else
                if (this.options.keepCurrentZoomLevel) {
                    var f = this.options.flyTo ? this._map.flyTo : this._map.panTo;
                    f.bind(this._map)([this._event.latitude, this._event.longitude]);
                } else {
                    var f = this.options.flyTo ? this._map.flyToBounds : this._map.fitBounds;
                    // Ignore zoom events while setting the viewport as these would stop following
                    this._ignoreEvent = true;
                    f.bind(this._map)(this.options.getLocationBounds(this._event), {
                        padding: this.options.circlePadding,
                        maxZoom: this.options.locateOptions.maxZoom
                    });
                    L.Util.requestAnimFrame(function(){
                        // Wait until after the next animFrame because the flyTo can be async
                        this._ignoreEvent = false;
                    }, this);

                }
            }
        },

        /**
         *
         */
        _drawCompass: function() {
            if (!this._event) {
                return;
            }

            var latlng = this._event.latlng;

            if (this.options.showCompass && latlng && this._compassHeading !== null) {
                var cStyle = this._isFollowing() ? this.options.followCompassStyle : this.options.compassStyle;
                if (!this._compass) {
                    this._compass = new this.options.compassClass(latlng, this._compassHeading, cStyle).addTo(this._layer);
                } else {
                    this._compass.setLatLng(latlng);
                    this._compass.setHeading(this._compassHeading);
                    // If the compassClass can be updated with setStyle, update it.
                    if (this._compass.setStyle) {
                        this._compass.setStyle(cStyle);
                    }
                }
                // 
            }
            if (this._compass && (!this.options.showCompass || this._compassHeading === null)) {
                this._compass.removeFrom(this._layer);
                this._compass = null;
            }
        },

        /**
         * Draw the marker and accuracy circle on the map.
         *
         * Uses the event retrieved from onLocationFound from the map.
         */
        _drawMarker: function() {
            if (this._event.accuracy === undefined) {
                this._event.accuracy = 0;
            }

            var radius = this._event.accuracy;
            var latlng = this._event.latlng;

            // circle with the radius of the location's accuracy
            if (this.options.drawCircle) {
                var style = this._isFollowing() ? this.options.followCircleStyle : this.options.circleStyle;

                if (!this._circle) {
                    this._circle = L.circle(latlng, radius, style).addTo(this._layer);
                } else {
                    this._circle.setLatLng(latlng).setRadius(radius).setStyle(style);
                }
            }

            var distance, unit;
            if (this.options.metric) {
                distance = radius.toFixed(0);
                unit =  this.options.strings.metersUnit;
            } else {
                distance = (radius * 3.2808399).toFixed(0);
                unit = this.options.strings.feetUnit;
            }

            // small inner marker
            if (this.options.drawMarker) {
                var mStyle = this._isFollowing() ? this.options.followMarkerStyle : this.options.markerStyle;
                if (!this._marker) {
                    this._marker = new this.options.markerClass(latlng, mStyle).addTo(this._layer);
                } else {
                    this._marker.setLatLng(latlng);
                    // If the markerClass can be updated with setStyle, update it.
                    if (this._marker.setStyle) {
                        this._marker.setStyle(mStyle);
                    }
                }
            }

            this._drawCompass();

            var t = this.options.strings.popup;
            function getPopupText() {
                if (typeof t === 'string') {
                    return L.Util.template(t, {distance: distance, unit: unit});
                } else if (typeof t === 'function') {
                    return t({distance: distance, unit: unit});
                } else {
                    return t;
                }
            }
            if (this.options.showPopup && t && this._marker) {
                this._marker
                    .bindPopup(getPopupText())
                    ._popup.setLatLng(latlng);
            }
            if (this.options.showPopup && t && this._compass) {
                this._compass
                    .bindPopup(getPopupText())
                    ._popup.setLatLng(latlng);
            }
        },

        /**
         * Remove the marker from map.
         */
        _removeMarker: function() {
            this._layer.clearLayers();
            this._marker = undefined;
            this._circle = undefined;
        },

        /**
         * Unload the plugin and all event listeners.
         * Kind of the opposite of onAdd.
         */
        _unload: function() {
            this.stop();
            this._map.off('unload', this._unload, this);
        },

        /**
         * Sets the compass heading
         */
        _setCompassHeading: function(angle) {
            if (!isNaN(parseFloat(angle)) && isFinite(angle)) {
                angle = Math.round(angle);

                this._compassHeading = angle;
                L.Util.requestAnimFrame(this._drawCompass, this);
            } else {
                this._compassHeading = null;
            }
        },

        /**
         * If the compass fails calibration just fail safely and remove the compass
         */
        _onCompassNeedsCalibration: function() {
            this._setCompassHeading();
        },

        /**
         * Process and normalise compass events
         */
        _onDeviceOrientation: function(e) {
            if (!this._active) {
                return;
            }

            if (e.webkitCompassHeading) {
                // iOS
                this._setCompassHeading(e.webkitCompassHeading);
            } else if (e.absolute && e.alpha) {
                // Android
                this._setCompassHeading(360 - e.alpha)
            }
        },

        /**
         * Calls deactivate and dispatches an error.
         */
        _onLocationError: function(err) {
            // ignore time out error if the location is watched
            if (err.code == 3 && this.options.locateOptions.watch) {
                return;
            }

            this.stop();
            this.options.onLocationError(err, this);
        },

        /**
         * Stores the received event and updates the marker.
         */
        _onLocationFound: function(e) {
            // no need to do anything if the location has not changed
            if (this._event &&
                (this._event.latlng.lat === e.latlng.lat &&
                 this._event.latlng.lng === e.latlng.lng &&
                     this._event.accuracy === e.accuracy)) {
                return;
            }

            if (!this._active) {
                // we may have a stray event
                return;
            }

            this._event = e;

            this._drawMarker();
            this._updateContainerStyle();

            switch (this.options.setView) {
                case 'once':
                    if (this._justClicked) {
                        this.setView();
                    }
                    break;
                case 'untilPan':
                    if (!this._userPanned) {
                        this.setView();
                    }
                    break;
                case 'untilPanOrZoom':
                    if (!this._userPanned && !this._userZoomed) {
                        this.setView();
                    }
                    break;
                case 'always':
                    this.setView();
                    break;
                case false:
                    // don't set the view
                    break;
            }

            this._justClicked = false;
        },

        /**
         * When the user drags. Need a separate event so we can bind and unbind event listeners.
         */
        _onDrag: function() {
            // only react to drags once we have a location
            if (this._event && !this._ignoreEvent) {
                this._userPanned = true;
                this._updateContainerStyle();
                this._drawMarker();
            }
        },

        /**
         * When the user zooms. Need a separate event so we can bind and unbind event listeners.
         */
        _onZoom: function() {
            // only react to drags once we have a location
            if (this._event && !this._ignoreEvent) {
                this._userZoomed = true;
                this._updateContainerStyle();
                this._drawMarker();
            }
        },

        /**
         * After a zoom ends update the compass and handle sideways zooms
         */
        _onZoomEnd: function() {
            if (this._event) {
                this._drawCompass();
            }

            if (this._event && !this._ignoreEvent) {
                // If we have zoomed in and out and ended up sideways treat it as a pan
                if (this._marker && !this._map.getBounds().pad(-.3).contains(this._marker.getLatLng())) {
                    this._userPanned = true;
                    this._updateContainerStyle();
                    this._drawMarker();
                }
            }
        },

        /**
         * Compute whether the map is following the user location with pan and zoom.
         */
        _isFollowing: function() {
            if (!this._active) {
                return false;
            }

            if (this.options.setView === 'always') {
                return true;
            } else if (this.options.setView === 'untilPan') {
                return !this._userPanned;
            } else if (this.options.setView === 'untilPanOrZoom') {
                return !this._userPanned && !this._userZoomed;
            }
        },

        /**
         * Check if location is in map bounds
         */
        _isOutsideMapBounds: function() {
            if (this._event === undefined) {
                return false;
            }
            return this._map.options.maxBounds &&
                !this._map.options.maxBounds.contains(this._event.latlng);
        },

        /**
         * Toggles button class between following and active.
         */
        _updateContainerStyle: function() {
            if (!this._container) {
                return;
            }

            if (this._active && !this._event) {
                // active but don't have a location yet
                this._setClasses('requesting');
            } else if (this._isFollowing()) {
                this._setClasses('following');
            } else if (this._active) {
                this._setClasses('active');
            } else {
                this._cleanClasses();
            }
        },

        /**
         * Sets the CSS classes for the state.
         */
        _setClasses: function(state) {
            if (state == 'requesting') {
                removeClasses(this._container, "active following");
                addClasses(this._container, "requesting");

                removeClasses(this._icon, this.options.icon);
                addClasses(this._icon, this.options.iconLoading);
            } else if (state == 'active') {
                removeClasses(this._container, "requesting following");
                addClasses(this._container, "active");

                removeClasses(this._icon, this.options.iconLoading);
                addClasses(this._icon, this.options.icon);
            } else if (state == 'following') {
                removeClasses(this._container, "requesting");
                addClasses(this._container, "active following");

                removeClasses(this._icon, this.options.iconLoading);
                addClasses(this._icon, this.options.icon);
            }
        },

        /**
         * Removes all classes from button.
         */
        _cleanClasses: function() {
            L.DomUtil.removeClass(this._container, "requesting");
            L.DomUtil.removeClass(this._container, "active");
            L.DomUtil.removeClass(this._container, "following");

            removeClasses(this._icon, this.options.iconLoading);
            addClasses(this._icon, this.options.icon);
        },

        /**
         * Reinitializes state variables.
         */
        _resetVariables: function() {
            // whether locate is active or not
            this._active = false;

            // true if the control was clicked for the first time
            // we need this so we can pan and zoom once we have the location
            this._justClicked = false;

            // true if the user has panned the map after clicking the control
            this._userPanned = false;

            // true if the user has zoomed the map after clicking the control
            this._userZoomed = false;
        }
    });

    L.control.locate = function (options) {
        return new L.Control.Locate(options);
    };

    return LocateControl;
}, window));
