//= require leaflet.maplibre

L.OSM.Shortbread = L.OSM.MaplibreGL.extend({
  onAdd: function (map) {
    L.OSM.MaplibreGL.prototype.onAdd.call(this, map);
    const styleURL = "https://vector.openstreetmap.org/demo/shortbread/" + this.options.styleName;
    this.getMaplibreMap().setStyle(styleURL, {
      transformStyle: (previousStyle, nextStyle) => ({
        ...nextStyle,
        sprite: [...nextStyle.sprite.map(s => {
          return {
            ...s,
            url: new URL(s.url, styleURL).href
          };
        })],
        // URL will % encode the {} in glyph and source URL so assemble them manually
        glyphs: (new URL(styleURL)).origin + nextStyle.glyphs,
        sources: {
          "versatiles-shortbread": {
            ...nextStyle.sources["versatiles-shortbread"],
            tiles: [(new URL(styleURL)).origin + nextStyle.sources["versatiles-shortbread"].tiles[0]]
          }
        }
      })
    });
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
