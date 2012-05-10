/* Copyright (c) 2006-2012 by OpenLayers Contributors (see authors.txt for
 * full list of contributors). Published under the 2-clause BSD license.
 * See license.txt in the OpenLayers distribution or repository for the
 * full text of the license. */

/**
 * @requires OpenLayers/Control.js
 * @requires OpenLayers/Events/buttonclick.js
 */

/**
 * Class: OkayPanZoom
 *
 * A version of PanZoom that's modified to be slightly less
 * abhorrent.
 *
 * Inherits from:
 *  - <OpenLayers.Control>
 */
var OkayPanZoom = OpenLayers.Class(OpenLayers.Control, {

    /**
     * APIProperty: slideFactor
     * {Integer} Number of pixels by which we'll pan the map in any direction
     *     on clicking the arrow buttons.  If you want to pan by some ratio
     *     of the map dimensions, use <slideRatio> instead.
     */
    slideFactor: 50,

    /**
     * Property: buttons
     * {Array(DOMElement)} Array of Button Divs
     */
    buttons: null,

    /**
     * Constructor: OpenLayers.Control.PanZoom
     *
     * Parameters:
     * options - {Object}
     */
    initialize: function(options) {
        OpenLayers.Control.prototype.initialize.apply(this, arguments);
    },

    /**
     * APIMethod: destroy
     */
    destroy: function() {
        if (this.map) {
            this.map.events.unregister("buttonclick", this, this.onButtonClick);
        }
        this.div.innerHTML = '';
        this.buttons = null;
        OpenLayers.Control.prototype.destroy.apply(this, arguments);
    },

    /**
     * Method: setMap
     *
     * Properties:
     * map - {<OpenLayers.Map>}
     */
    setMap: function(map) {
        OpenLayers.Control.prototype.setMap.apply(this, arguments);
        this.map.events.register("buttonclick", this, this.onButtonClick);
    },

    /**
     * Method: draw
     *
     * Parameters:
     * px - {<OpenLayers.Pixel>}
     *
     * Returns:
     * {DOMElement} A reference to the container div for the PanZoom control.
     */
    draw: function(px) {
        // initialize our internal div
        OpenLayers.Control.prototype.draw.apply(this, arguments);

        var button_types = [
            'panup',
            'panleft',
            'panright',
            'pandown',
            'zoomin',
            'zoomworld',
            'zoomout'];

        // place the controls
        this.buttons = [];

        for (var i = 0; i < button_types.length; i++) {
            var btn = this.div.appendChild(document.createElement('div'));
            btn.action = button_types[i];
            btn.className = 'olButton panzoom-' + button_types[i];
            btn.map = this.map;
            btn.slideFactor = this.slideFactor;
            OpenLayers.Event.observe(btn, 'mousedown',
                OpenLayers.Function.bindAsEventListener(this.onButtonClick, btn));
            this.buttons.push(btn);
        }

        return this.div;
    },

    /**
     * Method: onButtonClick
     *
     * Parameters:
     * evt - {Event}
     */
    onButtonClick: function(evt) {
        switch (this.action) {
            case "panup":
                this.map.pan(0, -this.slideFactor);
                break;
            case "pandown":
                this.map.pan(0, this.slideFactor);
                break;
            case "panleft":
                this.map.pan(-this.slideFactor, 0);
                break;
            case "panright":
                this.map.pan(this.slideFactor, 0);
                break;
            case "zoomin":
                this.map.zoomIn();
                break;
            case "zoomout":
                this.map.zoomOut();
                break;
            case "zoomworld":
                this.map.zoomToMaxExtent();
                break;
        }
    },

    CLASS_NAME: "OkayPanZoom"
});
