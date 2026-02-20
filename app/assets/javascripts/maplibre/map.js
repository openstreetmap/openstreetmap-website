//= require maplibre/controls
//= require maplibre/dom_util

maplibregl.Map.prototype._getUIString = function (key) {
  const snakeCaseKey = key.replaceAll(/(?<=\w)[A-Z]/g, "_$&").toLowerCase();
  return OSM.i18n.t(`javascripts.map.${snakeCaseKey}`);
};

OSM.MapLibre.showWebGLError = function (container) {
  const containerElement =
    typeof container === "string" ? document.getElementById(container) : container;

  if (containerElement) {
    fetch("/panes/maplibre/webgl_error")
      .then(response => response.text())
      .then(html => containerElement.innerHTML = html)
      .catch(() => containerElement.innerHTML = OSM.i18n.t("javascripts.map.webgl_error.webgl_is_required_for_this_map"));
  }
};

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

    let map;
    try {
      map = super({
        // Style validation only affects debug output.
        // Style errors are usually reported to authors, who should validate the style in CI for better error messages.
        validateStyle: false,
        ...rotationOptions,
        ...options
      });
    } catch (error) {
      const structuredError = JSON.parse(error.message);
      if (structuredError.type === "webglcontextcreationerror") {
        OSM.MapLibre.showWebGLError(options.container);
      }
      // the constructor panicked => we need to re-throw
      throw error;
    }
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
      style: OSM.LAYER_DEFINITIONS[0].style,
      attributionControl: false,
      allowRotation: false,
      maxPitch: 0,
      center: OSM.home ? [OSM.home.lon, OSM.home.lat] : [0, 0],
      zoom: OSM.home ? defaultHomeZoom : 0,
      zoomSnap: 1.0,
      ...options
    });
  }
};
