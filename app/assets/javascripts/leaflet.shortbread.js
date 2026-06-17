L.OSM.Shortbread = L.OSM.MaplibreGL.extend({
  onAdd: function (map) {
    L.OSM.MaplibreGL.prototype.onAdd.call(this, map);
    this.getMaplibreMap().setStyle("https://vector.openstreetmap.org/styles/svwd/svwd03style.json");
  },
  onRemove: function (map) {
    L.OSM.MaplibreGL.prototype.onRemove.call(this, map);
  }
});
