OSM.MapLibre.Popup = class extends maplibregl.Popup {
  constructor(options) {
    // General offset 5px for each side, but the offset depends on the popup position:
    // Popup above the marker -> lift it by height + 5px = 45px
    // Popup left the marker -> lift it by width/2 + 5px = 22.5px ~= 17px
    const offset = {
      "bottom": [0, -45],
      "bottom-left": [0, -45],
      "bottom-right": [0, -45],
      "top": [0, 5],
      "top-left": [0, 5],
      "top-right": [0, 5],
      // our marker is bigger at the top, but this does not attach there -> tucked 2px more
      "right": [-15, -10],
      "left": [15, -10]
    };
    super({ offset, ...options });
  }
};
