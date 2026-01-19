//= require maplibre-gl/dist/maplibre-gl
//= require maplibre.i18n
//= require maplibre/controls
//= require maplibre/dom_util
//= require maplibre/styles

OSM.MapLibre.Map = class extends maplibregl.Map {
  constructor({ allowRotation, ...options } = {}) {
    const rotationOptions = {};
    if (allowRotation === false) {
      Object.assign(rotationOptions, {
        rollEnabled: false,
        dragRotate: false,
        pitchWithRotate: false,
        bearingSnap: 180
      });
    }
    const map = super({
      ...rotationOptions,
      ...options
    });
    if (allowRotation === false) {
      map.touchZoomRotate.disableRotation();
      map.keyboard.disableRotation();
    }
    return map;
  }
};

OSM.MapLibre.SecondaryMap = class extends OSM.MapLibre.Map {
  constructor(options = {}) {
    const defaultHomeZoom = 11;
    super({
      container: "map",
      style: OSM.MapLibre.Styles.Mapnik,
      attributionControl: false,
      locale: OSM.MapLibre.Locale,
      allowRotation: false,
      maxPitch: 0,
      center: OSM.home ? [OSM.home.lon, OSM.home.lat] : [0, 0],
      zoom: OSM.home ? defaultHomeZoom : 0,
      ...options
    });
  }
};
