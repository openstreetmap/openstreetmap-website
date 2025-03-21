L.OSM.Zoom = L.Control.extend({
  options: {
    position: "topright"
  },

  onAdd: function (map) {
    const zoomName = "zoom",
          container = L.DomUtil.create("div", zoomName);

    this._map = map;

    this._zoomInButton = this._createButton(
      "", OSM.i18n.t("javascripts.map.zoom.in"), zoomName + "in", container, this._zoomIn, this);
    this._zoomOutButton = this._createButton(
      "", OSM.i18n.t("javascripts.map.zoom.out"), zoomName + "out", container, this._zoomOut, this);

    map.on("zoomend zoomlevelschange", this._updateDisabled, this);

    return container;
  },

  onRemove: function (map) {
    map.off("zoomend zoomlevelschange", this._updateDisabled, this);
  },

  _zoomIn: function (e) {
    this._map.zoomIn(e.shiftKey ? 3 : 1);
  },

  _zoomOut: function (e) {
    this._map.zoomOut(e.shiftKey ? 3 : 1);
  },

  _createButton: function (html, title, className, container, fn, context) {
    const link = L.DomUtil.create("a", "control-button " + className, container);
    const paths = { zoomin: "M16 8H12V4L11 3H10L9 4V8H5L4 9v1l1 1H9v4l1 1h1l1-1V11h4l1-1V9z", zoomout: "M4 9v1l1 1H16l1-1V9L16 8H5Z" };
    link.innerHTML = html;
    link.href = "#";
    link.title = title;

    $(L.SVG.create("svg"))
      .append($(L.SVG.create("path")).attr("d", paths[className]))
      .attr("fill", "currentColor")
      .attr("class", "h-100 w-100")
      .appendTo(link);

    const stop = L.DomEvent.stopPropagation;

    L.DomEvent
      .on(link, "click", stop)
      .on(link, "mousedown", stop)
      .on(link, "dblclick", stop)
      .on(link, "click", L.DomEvent.preventDefault)
      .on(link, "click", fn, context);

    return link;
  },

  _updateDisabled: function () {
    const map = this._map,
          className = "disabled";

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
