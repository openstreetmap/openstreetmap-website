//= require_self
//= require_tree ./engines

OSM.Directions = { engines: [] };

OSM.Directions.addEngine = function (engine, supportsHTTPS) {
  if (location.protocol === "http:" || supportsHTTPS) {
    engine.id = engine.provider + "_" + engine.mode;
    OSM.Directions.engines.push(engine);
  }
};
