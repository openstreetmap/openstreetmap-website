//= require maplibre-gl/dist/maplibre-gl
//= require maplibre.i18n

OSM.MapLibre.Styles.Mapnik = {
  version: 8,
  sources: {
    osm: {
      type: "raster",
      tiles: [
        "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
      ],
      tileSize: 256,
      maxzoom: 19
    }
  },
  layers: [
    {
      id: "osm",
      type: "raster",
      source: "osm"
    }
  ]
};

OSM.MapLibre.defaultHomeZoom = 11;
OSM.MapLibre.defaultSecondaryMapOptions = {
  container: "map",
  style: OSM.MapLibre.Styles.Mapnik,
  attributionControl: false,
  locale: OSM.MapLibre.Locale,
  rollEnabled: false,
  dragRotate: false,
  pitchWithRotate: false,
  bearingSnap: 180,
  maxPitch: 0,
  center: OSM.home ? [OSM.home.lon, OSM.home.lat] : [0, 0],
  zoom: OSM.home ? OSM.MapLibre.defaultHomeZoom : 0
};

// Helper function to create Leaflet style (SVG comes from Leaflet) markers for MapLibre
// new maplibregl.Marker({ color: color }) is simpler, but does not have the exact same gradient
OSM.MapLibre.getMarker = function ({ icon = "dot", color = "var(--marker-red)", ...options }) {
  const el = document.createElement("div");
  el.className = "maplibre-gl-marker";
  el.style.width = "25px";
  el.style.height = "40px";

  const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
  svg.setAttribute("viewBox", "0 0 25 40");
  svg.setAttribute("width", "25");
  svg.setAttribute("height", "40");
  svg.classList.add("pe-none");
  svg.style.overflow = "visible";

  // Use the marker icons from NoteMarker.svg
  const use1 = document.createElementNS("http://www.w3.org/2000/svg", "use");
  use1.setAttribute("href", "#pin-shadow");

  const use2 = document.createElementNS("http://www.w3.org/2000/svg", "use");
  use2.setAttribute("href", `#pin-${icon}`);
  use2.setAttribute("color", color);
  use2.classList.add("pe-auto");

  svg.appendChild(use1);
  svg.appendChild(use2);
  el.appendChild(svg);

  return new maplibregl.Marker({
    element: el,
    anchor: "bottom",
    offset: [0, 0],
    ...options
  });
};

// Helper function to create MapLibre popups that don't overlap with Leaflets' markers
OSM.MapLibre.getPopup = function (content) {
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
  return new maplibregl.Popup({ offset }).setHTML(content);
};
