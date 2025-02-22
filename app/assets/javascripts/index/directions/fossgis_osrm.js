// OSRM engine
// Doesn't yet support hints

(function () {
  function FOSSGISOSRMEngine(id, vehicleType) {
    let cachedHints = [];

    function _processDirections(route) {
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
        "depart": "start",
        "arrive": "destination"
      };
      const ICON_MAP = {
        "continue": 0,
        "merge right": 21,
        "merge left": 20,
        "off ramp right": 24,
        "off ramp left": 25,
        "on ramp right": 2,
        "on ramp left": 6,
        "fork right": 18,
        "fork left": 19,
        "end of road right": 22,
        "end of road left": 23,
        "turn straight": 0,
        "turn slight right": 1,
        "turn right": 2,
        "turn sharp right": 3,
        "turn uturn": 4,
        "turn slight left": 5,
        "turn left": 6,
        "turn sharp left": 7,
        "roundabout": 10,
        "rotary": 10,
        "exit roundabout": 10,
        "exit rotary": 10,
        "depart": 8,
        "arrive": 14
      };
      function numToWord(num) {
        return ["first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth", "tenth"][num - 1];
      }
      function getManeuverId(maneuver) {
        // special case handling
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

      const legs = route.legs.map(
        leg => leg.steps.map(function (step, idx) {
          const maneuver_id = getManeuverId(step.maneuver);

          const instrPrefix = "javascripts.directions.instructions.";
          let template = instrPrefix + INSTRUCTION_TEMPLATE[maneuver_id];

          const step_geometry = L.PolylineUtil.decode(step.geometry, { precision: 5 }).map(L.latLng);

          let instText = "<b>" + (idx + 1) + ".</b> ";
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
            name = I18n.t(instrPrefix + "unnamed");
            namedRoad = false;
          }

          if (step.maneuver.type.match(/^exit (rotary|roundabout)$/)) {
            instText += I18n.t(template, { name: name });
          } else if (step.maneuver.type.match(/^(rotary|roundabout)$/)) {
            if (step.maneuver.exit) {
              if (step.maneuver.exit <= 10) {
                instText += I18n.t(template + "_with_exit_ordinal", { exit: I18n.t(instrPrefix + "exit_counts." + numToWord(step.maneuver.exit)), name: name });
              } else {
                instText += I18n.t(template + "_with_exit", { exit: step.maneuver.exit, name: name });
              }
            } else {
              instText += I18n.t(template + "_without_exit", { name: name });
            }
          } else if (step.maneuver.type.match(/^(on ramp|off ramp)$/)) {
            const params = {};
            if (step.exits && step.maneuver.type.match(/^(off ramp)$/)) params.exit = step.exits;
            if (step.destinations) params.directions = destinations;
            if (namedRoad) params.directions = name;
            if (Object.keys(params).length > 0) {
              template = template + "_with_" + Object.keys(params).join("_");
            }
            instText += I18n.t(template, params);
          } else {
            instText += I18n.t(template + "_without_exit", { name: name });
          }
          return [
            [step.maneuver.location[1], step.maneuver.location[0]],
            ICON_MAP[maneuver_id],
            instText,
            step.distance,
            step_geometry
          ];
        })
      );

      return {
        line: legs.flat().flatMap(step => step[4]),
        legs,
        distance: route.distance,
        time: route.duration
      };
    }

    return {
      id: id,
      creditline: "<a href=\"https://routing.openstreetmap.de/about.html\" target=\"_blank\">OSRM (FOSSGIS)</a>",
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

        const req_path = "routed-" + vehicleType + "/route/v1/driving/" + points.map(p => p.lng + "," + p.lat).join(";");

        return fetch(OSM.FOSSGIS_OSRM_URL + req_path + "?" + query, { signal })
          .then(response => response.json())
          .then(response => {
            if (response.code !== "Ok") throw new Error();
            cachedHints = response.waypoints.map(wp => wp.hint);
            return _processDirections(response.routes[0]);
          });
      }
    };
  }

  OSM.Directions.addEngine(new FOSSGISOSRMEngine("fossgis_osrm_car", "car"), true);
  OSM.Directions.addEngine(new FOSSGISOSRMEngine("fossgis_osrm_bike", "bike"), true);
  OSM.Directions.addEngine(new FOSSGISOSRMEngine("fossgis_osrm_foot", "foot"), true);
}());
