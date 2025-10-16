//= require maplibre-gl
//= require @maplibre/maplibre-gl-leaflet

maplibregl.setRTLTextPlugin(OSM.RTL_TEXT_PLUGIN, true);

L.OSM.MaplibreGL = L.MaplibreGL.extend({
  getAttribution: function () {
    return this.options.attribution;
  }
});


// Two OHM additions follow (formerly in app/assets/javascripts/ohm.style.js.erb):

// 1. two sets of vector tiles: staging & production
// to use staging, either point your browser at http://localhost/ or else set &stagingtiles=1 in your URL params

const ohmTileServiceName = window.location.hostname.toLowerCase() == 'localhost' || window.location.hostname.toLowerCase() == 'staging.openhistoricalmap.org' !== false ? 'staging' : 'production';

const ohmTileServicesLists = {
  "production": [
    "https://vtiles.openhistoricalmap.org/maps/osm/{z}/{x}/{y}.pbf",
  ],
  "staging": [
    "https://vtiles.staging.openhistoricalmap.org/maps/osm/{z}/{x}/{y}.pbf",
  ],
};

// 2. multiple map styles
// in 2025 we began packaging these as the npm module, @openhistoricalmap/map-styles
// app/assets/javascripts/index.js is where we require @openhistoricalmap/map-styles/dist/ohm.styles
// the upstream conventions of config/layers.yml defines our L.MaplibreGL layers
// see timeslider.js which adds the TimeSlider to the map, keying it for those L.MaplibreGL layers

let ohmVectorStyles = {};
