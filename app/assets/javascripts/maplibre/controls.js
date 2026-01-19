OSM.MapLibre.NavigationControl = class extends maplibregl.NavigationControl {
  constructor(options = {}) {
    super({
      showCompass: false,
      ...options
    });
  }
};
