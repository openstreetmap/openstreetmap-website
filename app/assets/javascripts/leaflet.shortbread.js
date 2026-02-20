L.OSM.Shortbread = L.OSM.MaplibreGL.extend({
  onAdd: function (map) {
    L.OSM.MaplibreGL.prototype.onAdd.call(this, map);
    const styleURL = "https://vector.openstreetmap.org/styles/shortbread/" + this.options.styleName;
    this.getMaplibreMap().setStyle(styleURL);
  },
  onRemove: function (map) {
    L.OSM.MaplibreGL.prototype.onRemove.call(this, map);
  }
});

L.OSM.ShortbreadColorful = L.OSM.Shortbread.extend({
  options: {
    styleName: "colorful.json"
  }
});

L.OSM.ShortbreadEclipse = L.OSM.Shortbread.extend({
  options: {
    styleName: "eclipse.json"
  }
});
