/*
        Dervied from the OpenStreetBugs client, which is available
        under the following license.

        This OpenStreetBugs client is free software: you can redistribute it
        and/or modify it under the terms of the GNU Affero General Public License
        as published by the Free Software Foundation, either version 3 of the
        License, or (at your option) any later version.

        This file is distributed in the hope that it will be useful, but
        WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
        or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public
        License <http://www.gnu.org/licenses/> for more details.
*/

OpenLayers.Layer.Notes = new OpenLayers.Class(OpenLayers.Layer.Markers, {
    /**
     * The URL of the OpenStreetMap API.
     *
     * @var String
     */
    serverURL : "/api/0.6/",

    /**
     * Associative array (index: note ID) that is filled with the notes
     * loaded in this layer.
     *
     * @var String
     */
    notes : { },

    /**
     * The username to be used to change or create notes on OpenStreetMap.
     *
     * @var String
     */
    username : "NoName",

    /**
     * The icon to be used for an open note.
     *
     * @var OpenLayers.Icon
     */
    iconOpen : new OpenLayers.Icon("/images/open_note_marker.png", new OpenLayers.Size(22, 22), new OpenLayers.Pixel(-11, -11)),

    /**
     * The icon to be used for a closed note.
     *
     * @var OpenLayers.Icon
     */
    iconClosed : new OpenLayers.Icon("/images/closed_note_marker.png", new OpenLayers.Size(22, 22), new OpenLayers.Pixel(-11, -11)),

    /**
     * The icon to be used when adding a new note.
     *
     * @var OpenLayers.Icon
     */
    iconNew : new OpenLayers.Icon("/images/new_note_marker.png", new OpenLayers.Size(22, 22), new OpenLayers.Pixel(-11, -11)),

    /**
     * The projection of the coordinates sent by the OpenStreetMap API.
     *
     * @var OpenLayers.Projection
     */
    apiProjection : new OpenLayers.Projection("EPSG:4326"),

    /**
     * If this is set to true, the user may not commit comments or close notes.
     *
     * @var Boolean
     */
    readonly : false,

    /**
     * When the layer is hidden, all open popups are stored in this
     * array in order to be re-opened again when the layer is made
     * visible again.
     */
    reopenPopups : [ ],

    /**
     * A URL to append lon=123&lat=123&zoom=123 for the Permalinks.
     *
     * @var String
     */
    permalinkURL : "http://www.openstreetmap.org/",

    /**
     * A CSS file to be included. Set to null if you don’t need this.
     *
     * @var String
     */
    theme : "/stylesheets/notes.css",

    /**
     * @param String name
     */
    initialize: function(name, options) {
        OpenLayers.Layer.Markers.prototype.initialize.apply(this, [
            name,
            OpenLayers.Util.extend({
                opacity: 0.7,
                projection: new OpenLayers.Projection("EPSG:4326") }, options)
        ]);

        putAJAXMarker.layers.push(this);
        this.events.addEventType("markerAdded");

        this.events.register("visibilitychanged", this, this.updatePopupVisibility);
        this.events.register("visibilitychanged", this, this.loadNotes);

        if (this.theme) {
            // check existing links for equivalent url
            var addNode = true;
            var nodes = document.getElementsByTagName('link');
            for (var i = 0, len = nodes.length; i < len; ++i) {
                if (OpenLayers.Util.isEquivalentUrl(nodes.item(i).href, this.theme)) {
                    addNode = false;
                    break;
                }
            }
            // only add a new node if one with an equivalent url hasn't already
            // been added
            if (addNode) {
                var cssNode = document.createElement('link');
                cssNode.setAttribute('rel', 'stylesheet');
                cssNode.setAttribute('type', 'text/css');
                cssNode.setAttribute('href', this.theme);
                document.getElementsByTagName('head')[0].appendChild(cssNode);
            }
        }
    },

    /**
     * Called automatically called when the layer is added to a map.
     * Initialises the automatic note loading in the visible bounding box.
     */
    afterAdd: function() {
        var ret = OpenLayers.Layer.Markers.prototype.afterAdd.apply(this, arguments);

        this.map.events.register("moveend", this, this.loadNotes);
        this.loadNotes();

        return ret;
    },

    /**
     * At the moment the OpenStreetMap API responses to requests using
     * JavaScript code. This way the Same Origin Policy can be worked
     * around. Unfortunately, this makes communicating with the API a
     * bit too asynchronous, at the moment there is no way to tell to
     * which request the API actually responses.
     *
     * This method creates a new script HTML element that imports the
     * API request URL. The API JavaScript response then executes the
     * global functions provided below.
     *
     * @param String url The URL this.serverURL + url is requested.
     */
    apiRequest: function(url) {
        var script = document.createElement("script");
        script.type = "text/javascript";
        script.src = this.serverURL + url + "&nocache="+(new Date()).getTime();
        document.body.appendChild(script);
    },

    /**
     * Is automatically called when the visibility of the layer
     * changes. When the layer is hidden, all visible popups are
     * closed and their visibility is saved. When the layer is made
     * visible again, these popups are re-opened.
     */
    updatePopupVisibility: function() {
        if (this.getVisibility()) {
            for (var i =0 ; i < this.reopenPopups.length; i++)
                this.reopenPopups[i].show();

            this.reopenPopups = [ ];
        } else {
            for (var i = 0; i < this.markers.length; i++) {
                if (this.markers[i].feature.popup &&
                    this.markers[i].feature.popup.visible()) {
                    this.markers[i].feature.popup.hide();
                    this.reopenPopups.push(this.markers[i].feature.popup);
                }
            }
        }
    },

    /**
     * Sets the user name to be used for interactions with OpenStreetMap.
     */
    setUserName: function(username) {
        if (this.username == username)
            return;

        this.username = username;

        for (var i = 0; i < this.markers.length; i++) {
            var popup = this.markers[i].feature.popup;

            if (popup) {
                var els = popup.contentDom.getElementsByTagName("input");

                for (var j = 0; j < els.length; j++) {
                    if (els[j].className == "username")
                        els[j].value = username;
                }
            }
        }
    },

    /**
     * Returns the currently set username or “NoName” if none is set.
     */
    getUserName: function() {
        if(this.username)
            return this.username;
        else
            return "NoName";
    },

    /**
     * Loads the notes in the current bounding box. Is automatically
     * called by an event handler ("moveend" event) that is created in
     * the afterAdd() method.
     */
    loadNotes: function() {
        var bounds = this.map.getExtent();

        if (bounds && this.getVisibility()) {
            bounds.transform(this.map.getProjectionObject(), this.apiProjection);

            this.apiRequest("notes"
                            + "?bbox=" + this.round(bounds.left, 5)
                            + "," + this.round(bounds.bottom, 5)
                            + "," + this.round(bounds.right, 5)
                            + "," + this.round(bounds.top, 5));
        }
    },

    /**
     * Rounds the given number to the given number of digits after the
     * floating point.
     *
     * @param Number number
     * @param Number digits
     * @return Number
     */
    round: function(number, digits) {
        var scale = Math.pow(10, digits);

        return Math.round(number * scale) / scale;
    },

    /**
     * Adds an OpenLayers.Marker representing a note to the map. Is
     * usually called by loadNotes().
     *
     * @param Number id The note ID
     */
    createMarker: function(id) {
        if (this.notes[id]) {
            if (this.notes[id].popup && !this.notes[id].popup.visible())
                this.setPopupContent(this.notes[id].popup, id);

            if (this.notes[id].closed != putAJAXMarker.notes[id][2])
                this.notes[id].destroy();
            else
                return;
        }

        var lonlat = putAJAXMarker.notes[id][0].clone().transform(this.apiProjection, this.map.getProjectionObject());
        var comments = putAJAXMarker.notes[id][1];
        var closed = putAJAXMarker.notes[id][2];
        var icon = closed ? this.iconClosed : this.iconOpen;

        var feature = new OpenLayers.Feature(this, lonlat, {
            icon: icon.clone(),
            autoSize: true
        });
        feature.popupClass = OpenLayers.Popup.FramedCloud.Notes;
        feature.noteId = id;
        feature.closed = closed;
        this.notes[id] = feature;

        var marker = feature.createMarker();
        marker.feature = feature;
        marker.events.register("click", feature, this.markerClick);
        //marker.events.register("mouseover", feature, this.markerMouseOver);
        //marker.events.register("mouseout", feature, this.markerMouseOut);
        this.addMarker(marker);

        this.events.triggerEvent("markerAdded");
    },

    /**
     * Recreates the content of the popup of a marker.
     *
     * @param OpenLayers.Popup popup
     * @param Number id The note ID
     */
    setPopupContent: function(popup, id) {
        var el1,el2,el3;
        var layer = this;

        var newContent = document.createElement("div");

        el1 = document.createElement("h3");
        el1.appendChild(document.createTextNode(putAJAXMarker.notes[id][2] ? i18n("javascripts.note.closed") : i18n("javascripts.note.open")));

        el1.appendChild(document.createTextNode(" ["));
        el2 = document.createElement("a");
        el2.href = "/browse/note/" + id;
        el2.onclick = function() {
            layer.map.setCenter(putAJAXMarker.notes[id][0].clone().transform(layer.apiProjection, layer.map.getProjectionObject()), 15);
        };
        el2.appendChild(document.createTextNode(i18n("javascripts.note.details")));
        el1.appendChild(el2);
        el1.appendChild(document.createTextNode("]"));

        if (this.permalinkURL) {
            el1.appendChild(document.createTextNode(" ["));
            el2 = document.createElement("a");
            el2.href = this.permalinkURL + (this.permalinkURL.indexOf("?") == -1 ? "?" : "&") + "lon="+putAJAXMarker.notes[id][0].lon+"&lat="+putAJAXMarker.notes[id][0].lat+"&zoom=15";
            el2.appendChild(document.createTextNode(i18n("javascripts.note.permalink")));
            el1.appendChild(el2);
            el1.appendChild(document.createTextNode("]"));
        }
        newContent.appendChild(el1);

        var containerDescription = document.createElement("div");
        newContent.appendChild(containerDescription);

        var containerChange = document.createElement("div");
        newContent.appendChild(containerChange);

        var displayDescription = function() {
            containerDescription.style.display = "block";
            containerChange.style.display = "none";
            popup.updateSize();
        };
        var displayChange = function() {
            containerDescription.style.display = "none";
            containerChange.style.display = "block";
            popup.updateSize();
        };
        displayDescription();

        el1 = document.createElement("dl");
        for (var i = 0; i < putAJAXMarker.notes[id][1].length; i++) {
            el2 = document.createElement("dt");
            el2.className = (i == 0 ? "note-description" : "note-comment");
            el2.appendChild(document.createTextNode(i == 0 ? i18n("javascripts.note.description") : i18n("javascripts.note.comment")));
            el1.appendChild(el2);
            el2 = document.createElement("dd");
            el2.className = (i == 0 ? "note-description" : "note-comment");
            el2.appendChild(document.createTextNode(putAJAXMarker.notes[id][1][i]));
            el1.appendChild(el2);
            if (i == 0) {
                el2 = document.createElement("br");
                el1.appendChild(el2);
            };
        }
        containerDescription.appendChild(el1);

        if (putAJAXMarker.notes[id][2]) {
            el1 = document.createElement("p");
            el1.className = "note-fixed";
            el2 = document.createElement("em");
            el2.appendChild(document.createTextNode(i18n("javascripts.note.render_warning")));
            el1.appendChild(el2);
            containerDescription.appendChild(el1);
        } else if (!this.readonly) {
            el1 = document.createElement("div");
            el2 = document.createElement("input");
            el2.setAttribute("type", "button");
            el2.onclick = function() {
                displayChange();
            };
            el2.value = i18n("javascripts.note.update");
            el1.appendChild(el2);
            containerDescription.appendChild(el1);

            var el_form = document.createElement("form");
            el_form.onsubmit = function() {
                if (inputComment.value.match(/^\s*$/))
                    return false;
                layer.submitComment(id, inputComment.value);
                layer.hidePopup(popup);
                return false;
            };

            el1 = document.createElement("dl");
            el2 = document.createElement("dt");
            el2.appendChild(document.createTextNode(i18n("javascripts.note.nickname")));
            el1.appendChild(el2);
            el2 = document.createElement("dd");
            var inputUsername = document.createElement("input");
            var inputUsername = document.createElement("input");;
            if (typeof loginName === "undefined") {
                inputUsername.value = this.username;
            } else {
                inputUsername.value = loginName;
                inputUsername.setAttribute("disabled", "true");
            }
            inputUsername.className = "username";
            inputUsername.onkeyup = function() {
                layer.setUserName(inputUsername.value);
            };
            el2.appendChild(inputUsername);
            el3 = document.createElement("a");
            el3.setAttribute("href", "login");
            el3.className = "hide_if_logged_in";
            el3.appendChild(document.createTextNode(i18n("javascripts.note.login")));
            el2.appendChild(el3)
            el1.appendChild(el2);

            el2 = document.createElement("dt");
            el2.appendChild(document.createTextNode(i18n("javascripts.note.comment")));
            el1.appendChild(el2);
            el2 = document.createElement("dd");
            var inputComment = document.createElement("textarea");
            inputComment.setAttribute("cols",40);
            inputComment.setAttribute("rows",3);

            el2.appendChild(inputComment);
            el1.appendChild(el2);

            el_form.appendChild(el1);

            el1 = document.createElement("ul");
            el1.className = "buttons";
            el2 = document.createElement("li");
            el3 = document.createElement("input");
            el3.setAttribute("type", "button");
            el3.onclick = function() {
                this.form.onsubmit();
                return false;
            };
            el3.value = i18n("javascripts.note.add_comment");
            el2.appendChild(el3);
            el1.appendChild(el2);

            el2 = document.createElement("li");
            el3 = document.createElement("input");
            el3.setAttribute("type", "button");
            el3.onclick = function() {
                this.form.onsubmit();
                layer.closeNote(id);
                popup.hide();
                return false;
            };
            el3.value = i18n("javascripts.note.close");
            el2.appendChild(el3);
            el1.appendChild(el2);
            el_form.appendChild(el1);
            containerChange.appendChild(el_form);

            el1 = document.createElement("div");
            el2 = document.createElement("input");
            el2.setAttribute("type", "button");
            el2.onclick = function(){ displayDescription(); };
            el2.value = i18n("javascripts.note.cancel");
            el1.appendChild(el2);
            containerChange.appendChild(el1);
        }

        popup.setContentHTML(newContent);
    },

    /**
     * Creates a new note.
     *
     * @param OpenLayers.LonLat lonlat The coordinates in the API projection.
     * @param String description
     */
    createNote: function(lonlat, description) {
        this.apiRequest("note/create"
                        + "?lat=" + encodeURIComponent(lonlat.lat)
                        + "&lon=" + encodeURIComponent(lonlat.lon)
                        + "&text=" + encodeURIComponent(description)
                        + "&name=" + encodeURIComponent(this.getUserName())
                        + "&format=js");
    },

    /**
     * Adds a comment to a note.
     *
     * @param Number id
     * @param String comment
     */
    submitComment: function(id, comment) {
        this.apiRequest("note/" + encodeURIComponent(id) + "/comment"
                        + "?text=" + encodeURIComponent(comment)
                        + "&name=" + encodeURIComponent(this.getUserName())
                        + "&format=js");
    },

    /**
     * Marks a note as fixed.
     *
     * @param Number id
     */
    closeNote: function(id) {
        this.apiRequest("note/" + encodeURIComponent(id) + "/close"
                        + "?format=js");
    },

    /**
     * Removes the content of a marker popup (to reduce the amount of
     * needed resources).
     *
     * @param OpenLayers.Popup popup
     */
    resetPopupContent: function(popup) {
        if (popup)
            popup.setContentHTML(document.createElement("div"));
    },

    /**
     * Makes the popup of the given marker visible. Makes sure that
     * the popup content is created if it does not exist yet.
     *
     * @param OpenLayers.Feature feature
     */
    showPopup: function(feature) {
        var popup = feature.popup;

        if (!popup) {
            popup = feature.createPopup(true);

            popup.events.register("close", this, function() {
                this.resetPopupContent(popup);
            });
        }

        this.setPopupContent(popup, feature.noteId);

        if (!popup.map)
            this.map.addPopup(popup);

        popup.updateSize();

        if (!popup.visible())
            popup.show();
    },

    /**
     * Hides the popup of the given marker.
     *
     * @param OpenLayers.Feature feature
     */
    hidePopup: function(feature) {
        if (feature.popup && feature.popup.visible()) {
            feature.popup.hide();
            feature.popup.events.triggerEvent("close");
        }
    },

    /**
     * Is run on the “click” event of a marker in the context of its
     * OpenLayers.Feature. Toggles the visibility of the popup.
     */
    markerClick: function(e) {
        var feature = this;

        if (feature.popup && feature.popup.visible())
            feature.layer.hidePopup(feature);
        else
            feature.layer.showPopup(feature);

        OpenLayers.Event.stop(e);
    },

    /**
     * Is run on the “mouseover” event of a marker in the context of
     * its OpenLayers.Feature. Makes the popup visible.
     */
    markerMouseOver: function(e) {
        var feature = this;

        feature.layer.showPopup(feature);

        OpenLayers.Event.stop(e);
    },

    /**
     * Is run on the “mouseout” event of a marker in the context of
     * its OpenLayers.Feature. Hides the popup (if it has not been
     * clicked).
     */
    markerMouseOut: function(e) {
        var feature = this;

        if (feature.popup && feature.popup.visible())
            feature.layer.hidePopup(feature);

        OpenLayers.Event.stop(e);
    },

    /**
     * Add a new note.
     */
    addNote: function(lonlat) {
        var layer = this;
        var map = this.map;
        var lonlatApi = lonlat.clone().transform(map.getProjectionObject(), this.apiProjection);
        var feature = new OpenLayers.Feature(this, lonlat, { icon: this.iconNew.clone(), autoSize: true });
        feature.popupClass = OpenLayers.Popup.FramedCloud.Notes;
        var marker = feature.createMarker();
        marker.feature = feature;
        this.addMarker(marker);


        /** Implement a drag and drop for markers */
        /* TODO: veryfy that the scoping of variables works correctly everywhere */
        var dragging = false;
        var dragMove = function(e) {
            lonlat = map.getLonLatFromViewPortPx(e.xy);
            lonlatApi = lonlat.clone().transform(map.getProjectionObject(), map.noteLayer.apiProjection);
            marker.moveTo(map.getLayerPxFromViewPortPx(e.xy));
            marker.popup.moveTo(map.getLayerPxFromViewPortPx(e.xy));
            marker.popup.updateRelativePosition();
            return false;
        };
        var dragComplete = function(e) {
            map.events.unregister("mousemove", map, dragMove);
            map.events.unregister("mouseup", map, dragComplete);
            dragMove(e);
            dragging = false;
            return false;
        };

        marker.events.register("mouseover", this, function() {
            map.viewPortDiv.style.cursor = "move";
        });
        marker.events.register("mouseout", this, function() {
            if (!dragging)
                map.viewPortDiv.style.cursor = "default";
        });
        marker.events.register("mousedown", this, function() {
            dragging = true;
            map.events.register("mousemove", map, dragMove);
            map.events.register("mouseup", map, dragComplete);
            return false;
        });

        var newContent = document.createElement("div");
        var el1,el2,el3;
        el1 = document.createElement("h3");
        el1.appendChild(document.createTextNode(i18n("javascripts.note.create_title")));
        newContent.appendChild(el1);
        newContent.appendChild(document.createTextNode(i18n("javascripts.note.create_help1")));
        newContent.appendChild(document.createElement("br"));
        newContent.appendChild(document.createTextNode(i18n("javascripts.note.create_help2")));
        newContent.appendChild(document.createElement("br"));
        newContent.appendChild(document.createElement("br"));

        var el_form = document.createElement("form");

        el1 = document.createElement("dl");
        el2 = document.createElement("dt");
        el2.appendChild(document.createTextNode(i18n("javascripts.note.nickname")));
        el1.appendChild(el2);
        el2 = document.createElement("dd");
        var inputUsername = document.createElement("input");;
        if (typeof loginName === 'undefined') {
            inputUsername.value = this.username;
        } else {
            inputUsername.value = loginName;
            inputUsername.setAttribute('disabled','true');
        }
        inputUsername.className = "username";

        inputUsername.onkeyup = function() {
            this.setUserName(inputUsername.value);
        };
        el2.appendChild(inputUsername);
        el3 = document.createElement("a");
        el3.setAttribute("href","login");
        el3.className = "hide_if_logged_in";
        el3.appendChild(document.createTextNode(i18n("javascripts.note.login")));
        el2.appendChild(el3);
        el1.appendChild(el2);
        el2 = document.createElement("br");
        el1.appendChild(el2);

        el2 = document.createElement("dt");
        el2.appendChild(document.createTextNode(i18n("javascripts.note.description")));
        el1.appendChild(el2);
        el2 = document.createElement("dd");
        var inputDescription = document.createElement("textarea");
        inputDescription.setAttribute("cols",40);
        inputDescription.setAttribute("rows",3);
        el2.appendChild(inputDescription);
        el1.appendChild(el2);
        el_form.appendChild(el1);

        el1 = document.createElement("div");
        el2 = document.createElement("input");
        el2.setAttribute("type", "button");
        el2.value = i18n("javascripts.note.report");
        el2.onclick = function() {
            layer.createNote(lonlatApi, inputDescription.value);
            marker.feature = null;
            feature.destroy();
            return false;
        };
        el1.appendChild(el2);
        el2 = document.createElement("input");
        el2.setAttribute("type", "button");
        el2.value = i18n("javascripts.note.cancel");
        el2.onclick = function(){ feature.destroy(); };
        el1.appendChild(el2);
        el_form.appendChild(el1);
        newContent.appendChild(el_form);

        el2 = document.createElement("hr");
        el1.appendChild(el2);
        el2 = document.createElement("a");
        el2.setAttribute("href","edit");
        el2.appendChild(document.createTextNode(i18n("javascripts.note.edityourself")));
        el1.appendChild(el2);

        feature.data.popupContentHTML = newContent;
        var popup = feature.createPopup(true);
        popup.events.register("close", this, function() {
            feature.destroy();
        });
        map.addPopup(popup);
        popup.updateSize();
        marker.popup = popup;
    },

    CLASS_NAME: "OpenLayers.Layer.Notes"
});


/**
 * This class changes the usual OpenLayers.Popup.FramedCloud class by
 * using a DOM element instead of an innerHTML string as content for
 * the popup.  This is necessary for creating valid onclick handlers
 * that still work with multiple Notes layer objects.
 */
OpenLayers.Popup.FramedCloud.Notes = new OpenLayers.Class(OpenLayers.Popup.FramedCloud, {
    contentDom : null,
    autoSize : true,

    /**
     * See OpenLayers.Popup.FramedCloud.initialize() for
     * parameters. As fourth parameter, pass a DOM node instead of a
     * string.
     */
    initialize: function() {
        this.displayClass = this.displayClass + " " + this.CLASS_NAME.replace("OpenLayers.", "ol").replace(/\./g, "");

        var args = new Array(arguments.length);
        for(var i=0; i<arguments.length; i++)
            args[i] = arguments[i];

        // Unset original contentHTML parameter
        args[3] = null;

        var closeCallback = arguments[6];

        // Add close event trigger to the closeBoxCallback parameter
        args[6] = function(e){ if(closeCallback) closeCallback(); else this.hide(); OpenLayers.Event.stop(e); this.events.triggerEvent("close"); };

        OpenLayers.Popup.FramedCloud.prototype.initialize.apply(this, args);

        this.events.addEventType("close");

        this.setContentHTML(arguments[3]);
    },

    /**
     * Like OpenLayers.Popup.FramedCloud.setContentHTML(), but takes a
     * DOM element as parameter.
     */
    setContentHTML: function(contentDom) {
        if(contentDom != null)
            this.contentDom = contentDom;

        if(this.contentDiv == null || this.contentDom == null || this.contentDom == this.contentDiv.firstChild)
            return;

        while(this.contentDiv.firstChild)
            this.contentDiv.removeChild(this.contentDiv.firstChild);

        this.contentDiv.appendChild(this.contentDom);

        // Copied from OpenLayers.Popup.setContentHTML():
        if(this.autoSize)
        {
            this.registerImageListeners();
            this.updateSize();
        }
    },

    destroy: function() {
        this.contentDom = null;
        OpenLayers.Popup.FramedCloud.prototype.destroy.apply(this, arguments);
    },

    CLASS_NAME: "OpenLayers.Popup.FramedCloud.Notes"
});


/**
 * This global function is executed by the OpenStreetMap API getBugs script.
 *
 * Each Notes layer adds itself to the putAJAXMarker.layer array. The
 * putAJAXMarker() function executes the createMarker() method on each
 * layer in that array each time it is called. This has the
 * side-effect that notes displayed in one map on a page are already
 * loaded on the other map as well.
 */
function putAJAXMarker(id, lon, lat, text, closed)
{
    var comments = text.split(/<hr \/>/);
    for(var i=0; i<comments.length; i++)
        comments[i] = comments[i].replace(/&quot;/g, "\"").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&amp;/g, "&");
    putAJAXMarker.notes[id] = [
        new OpenLayers.LonLat(lon, lat),
        comments,
        closed
    ];
    for(var i=0; i<putAJAXMarker.layers.length; i++)
        putAJAXMarker.layers[i].createMarker(id);
}

/**
 * This global function is executed by the OpenStreetMap API. The
 * “create note”, “comment” and “close note” scripts execute it to give
 * information about their success.
 *
 * In case of success, this function is called without a parameter, in
 * case of an error, the error message is passed. This is lousy
 * workaround to make it any functional at all, the OSB API is likely
 * to be extended later (then it will provide additional information
 * such as the ID of a created note and similar).
 */
function osbResponse(error)
{
    if(error)
        alert("Error: "+error);

    for(var i=0; i<putAJAXMarker.layers.length; i++)
        putAJAXMarker.layers[i].loadNotes();
}

putAJAXMarker.layers = [ ];
putAJAXMarker.notes = { };
