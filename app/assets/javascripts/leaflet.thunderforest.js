//= require maplibre/i18n

L.OSM.ThunderforestVector = L.OSM.MaplibreGL.extend({
  onAdd: function (map) {
    L.OSM.MaplibreGL.prototype.onAdd.call(this, map);
    const styleURL = "https://api.thunderforest.com/styles/" + this.options.styleName + "/style.json?key=" + this.options.apikey;
    this.getMaplibreMap().setStyle(styleURL);
  },
  onRemove: function (map) {
    L.OSM.MaplibreGL.prototype.onRemove.call(this, map);
  }
});

L.OSM.TransportMapVector = L.OSM.ThunderforestVector.extend({
  options: {
    styleName: "transport"
  }
});

L.OSM.TransportDarkMapVector = L.OSM.ThunderforestVector.extend({
  options: {
    styleName: "transport-dark"
  }
});
