L.OSM.OHM = L.OSM.MaplibreGL.extend({
  onAdd: function (map) {
    L.OSM.MaplibreGL.prototype.onAdd.call(this, map);
    this.getMaplibreMap().setStyle(ohmVectorStyles[this.options.name.replaceAll(' ','')]);
  },
  onRemove: function (map) {
    L.OSM.MaplibreGL.prototype.onRemove.call(this, map);
  }
});

L.OSM.Historical = L.OSM.OHM.extend({});
L.OSM.Railway = L.OSM.OHM.extend({});
L.OSM.Woodblock = L.OSM.OHM.extend({});
L.OSM.JapaneseScroll = L.OSM.OHM.extend({});
