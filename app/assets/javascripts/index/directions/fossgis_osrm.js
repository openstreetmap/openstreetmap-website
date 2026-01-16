// OSRM engine
// Doesn't yet support hints

(function () {
  function FOSSGISOSRMEngine(modeId, vehicleType, srv) {
    let cachedHints = [];

    function getInstructionText(step) {
      const INSTRUCTION_TEMPLATE = {
        "continue": "continue",
        "merge right": "merge_right",
        "merge left": "merge_left",
        "off ramp right": "offramp_right",
        "off ramp left": "offramp_left",
        "on ramp right": "onramp_right",
        "on ramp left": "onramp_left",
        "fork right": "fork_right",
        "fork left": "fork_left",
        "end of road right": "endofroad_right",
        "end of road left": "endofroad_left",
        "turn straight": "continue",
        "turn slight right": "slight_right",
        "turn right": "turn_right",
        "turn sharp right": "sharp_right",
        "turn uturn": "uturn",
        "turn sharp left": "sharp_left",
        "turn left": "turn_left",
        "turn slight left": "slight_left",
        "roundabout": "roundabout",
        "rotary": "roundabout",
        "exit roundabout": "exit_roundabout",
        "exit rotary": "exit_roundabout",
        "ferry": "ferry",
        "depart": "start",
        "arrive": "destination"
      };

      function numToWord(num) {
        return ["first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth", "tenth"][num - 1];
      }

      const instrPrefix = "javascripts.directions.instructions.";
      let template = instrPrefix + INSTRUCTION_TEMPLATE[step.maneuverId];

      const destinations = "<b>" + step.destinations + "</b>";
      let namedRoad = true;
      let name;

      if (step.name && step.ref) {
        name = "<b>" + step.name + " (" + step.ref + ")</b>";
      } else if (step.name) {
        name = "<b>" + step.name + "</b>";
      } else if (step.ref) {
        name = "<b>" + step.ref + "</b>";
      } else {
        name = OSM.i18n.t(instrPrefix + "unnamed");
        namedRoad = false;
      }

      if (step.maneuver.type.match(/^exit (rotary|roundabout)$/)) {
        return OSM.i18n.t(template, { name: name });
      }

      if (step.maneuver.type.match(/^(rotary|roundabout)$/)) {
        if (!step.maneuver.exit) {
          return OSM.i18n.t(template + "_without_exit", { name: name });
        }

        if (step.maneuver.exit > 10) {
          return OSM.i18n.t(template + "_with_exit", { exit: step.maneuver.exit, name: name });
        }

        return OSM.i18n.t(template + "_with_exit_ordinal", { exit: OSM.i18n.t(instrPrefix + "exit_counts." + numToWord(step.maneuver.exit)), name: name });
      }

      if (!step.maneuver.type.match(/^(on ramp|off ramp)$/)) {
        return OSM.i18n.t(template + "_without_exit", { name: name });
      }

      const params = {};

      if (step.exits && step.maneuver.type.match(/^(off ramp)$/)) params.exit = step.exits;
      if (step.destinations) params.directions = destinations;
      if (namedRoad) params.directions = name;

      if (Object.keys(params).length > 0) {
        template = template + "_with_" + Object.keys(params).join("_");
      }

      return OSM.i18n.t(template, params);
    }

    function _processDirections(leg) {
      function getManeuverId({ maneuver, mode, intersections }) {
        // special case handling
        if (mode === "ferry") return "ferry";
        if (intersections.some(i => i.classes?.includes("ferry"))) return "ferry";

        switch (maneuver.type) {
          case "on ramp":
          case "off ramp":
          case "merge":
          case "end of road":
          case "fork":
            return maneuver.type + " " + (maneuver.modifier.indexOf("left") >= 0 ? "left" : "right");
          case "depart":
          case "arrive":
          case "roundabout":
          case "rotary":
          case "exit roundabout":
          case "exit rotary":
            return maneuver.type;
          case "roundabout turn":
          case "turn":
            return "turn " + maneuver.modifier;
            // for unknown types the fallback is turn
          default:
            return "turn " + maneuver.modifier;
        }
      }

      const ICON_MAP = {
        "continue": "straight",
        "merge right": "merge-right",
        "merge left": "merge-left",
        "off ramp right": "exit-right",
        "off ramp left": "exit-left",
        "on ramp right": "right",
        "on ramp left": "left",
        "fork right": "fork-right",
        "fork left": "fork-left",
        "end of road right": "end-of-road-right",
        "end of road left": "end-of-road-left",
        "turn straight": "straight",
        "turn slight right": "slight-right",
        "turn right": "right",
        "turn sharp right": "sharp-right",
        "turn uturn": "u-turn-left",
        "turn slight left": "slight-left",
        "turn left": "left",
        "turn sharp left": "sharp-left",
        "roundabout": "roundabout",
        "rotary": "roundabout",
        "exit roundabout": "roundabout",
        "exit rotary": "roundabout",
        "ferry": "ferry",
        "depart": "start",
        "arrive": "destination"
      };

      for (const step of leg.steps) step.maneuverId = getManeuverId(step);

      const steps = leg.steps.map(step => [
        ICON_MAP[step.maneuverId],
        getInstructionText(step),
        step.distance,
        L.PolylineUtil.decode(step.geometry, { precision: 5 })
      ]);

      return {
        line: steps.flatMap(step => step[3]),
        steps,
        distance: leg.distance,
        time: leg.duration
      };
    }

    return {
      mode: modeId,
      provider: "fossgis_osrm",
      draggable: true,

      getRoute: function (points, signal) {
        const query = new URLSearchParams({
          overview: "false",
          geometries: "polyline",
          steps: true
        });

        if (cachedHints.length === points.length) {
          query.set("hints", cachedHints.join(";"));
        } else {
          // invalidate cache
          cachedHints = [];
        }

        const demoQuery = new URLSearchParams({ srv: srv });

        for (const { lat, lng } of points) {
          demoQuery.append("loc", [lat, lng]);
        }

        const meta = {
          credit: "OSRM (FOSSGIS)",
          creditlink: "https://routing.openstreetmap.de/about.html",
          demolink: "https://routing.openstreetmap.de/?" + demoQuery
        };
        const req_path = "routed-" + vehicleType + "/route/v1/driving/" + points.map(p => p.lng + "," + p.lat).join(";");

        return fetch(OSM.FOSSGIS_OSRM_URL + req_path + "?" + query, { signal })
          .then(response => response.json())
          .then(response => {
            if (response.code !== "Ok") throw new Error();

            cachedHints = response.waypoints.map(wp => wp.hint);

            return { ... _processDirections(response.routes[0].legs[0]), ...meta };
          });
      }
    };
  }

  OSM.Directions.addEngine(new FOSSGISOSRMEngine("car", "car", "0"), true);
  OSM.Directions.addEngine(new FOSSGISOSRMEngine("bicycle", "bike", "1"), true);
  OSM.Directions.addEngine(new FOSSGISOSRMEngine("foot", "foot", "2"), true);
}());
