//= require_self
//= require_tree ./engines

OSM.directionsEngines = [];

OSM.directionsEngines.add = function (engine, supportsHTTPS) {
  if (location.protocol === "http:" || supportsHTTPS) {
    engine.id = engine.provider + "_" + engine.mode;
    OSM.directionsEngines.push(engine);
  }
};
