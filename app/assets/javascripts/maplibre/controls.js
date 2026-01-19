OSM.MapLibre.GeolocateControl = class extends maplibregl.GeolocateControl {
  constructor({ positionOptions = {}, ...options } = {}) {
    super({
      positionOptions: {
        enableHighAccuracy: true,
        ...positionOptions
      },
      trackUserLocation: true,
      ...options
    });
  }
};

OSM.MapLibre.NavigationControl = class extends maplibregl.NavigationControl {
  constructor(options = {}) {
    super({
      showCompass: false,
      ...options
    });
  }
};
