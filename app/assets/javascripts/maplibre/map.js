//= require maplibre/controls
//= require maplibre/dom_util
//= require maplibre/styles

maplibregl.Map.prototype._getUIString = function (key) {
  const snakeCaseKey = key.replaceAll(/(?<=\w)[A-Z]/g, "_$&").toLowerCase();
  return OSM.i18n.t(`javascripts.map.${snakeCaseKey}`);
};

OSM.MapLibre.showWebGLError = function (container) {
  const containerElement =
    typeof container === "string"
      ? document.getElementById(container)
      : container;

  if (containerElement) {
    const errorDiv = document.createElement("div");
    errorDiv.className = "maplibre-error";
    errorDiv.setAttribute("data-compact-message", "WebGL is required for this map.");
    errorDiv.innerHTML = `
      <p>
        We are sorry, but it seems that your <b>browser does not support WebGL</b>, a technology for rendering 2D and 3D graphics in your browser.
        <b>WebGL is required to display this map.</b>
      </p>
      <p><strong>To fix this:</strong></p>
      <ul>
        <li>Upgrade your browser to the latest version.</li>
        <li>Use a different browser such as Firefox, Safari or Chrome.</li>
        <li>Enable WebGL in your browser settings.</li>
      </ul>
    `;

    containerElement.innerHTML = "";
    containerElement.appendChild(errorDiv);
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
      style: OSM.MapLibre.Styles.Mapnik(),
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
