L.OSM.OHM = L.OSM.MaplibreGL.extend({
  onAdd: function (map) {
    L.OSM.MaplibreGL.prototype.onAdd.call(this, map);
    this.getMaplibreMap().setStyle(ohmVectorStyles[this.ohmStyleName]);
  },
  onRemove: function (map) {
    L.OSM.MaplibreGL.prototype.onRemove.call(this, map);
  }
});

L.OSM.Historical = L.OSM.OHM.extend({ ohmStyleName: "Historical" });
L.OSM.Railway = L.OSM.OHM.extend({ ohmStyleName: "Railway"});
L.OSM.Woodblock = L.OSM.OHM.extend({ ohmStyleName: "Woodblock" });
L.OSM.JapaneseScroll = L.OSM.OHM.extend({ ohmStyleName: "JapaneseScroll" });
