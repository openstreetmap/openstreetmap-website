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
