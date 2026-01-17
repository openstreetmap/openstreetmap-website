(function () {
  function GraphHopperEngine(modeId, vehicleType, profile) {
    const GH_INSTR_MAP = {
      "-3": "sharp-left",
      "-2": "left",
      "-1": "slight-left",
      "0": "straight",
      "1": "slight-right",
      "2": "right",
      "3": "sharp-right",
      "4": "destination", // finish reached
      "5": "destination", // via reached
      "6": "roundabout",
      "-7": "fork-left",
      "7": "fork-right",
      "-98": "u-turn-left", // unknown direction u-turn
      "-8": "u-turn-left", // left u-turn
      "8": "u-turn-right" // right u-turn
    };

    function _processDirections(path) {
      const line = L.PolylineUtil.decode(path.points);

      const steps = path.instructions.map(instr => [
        GH_INSTR_MAP[instr.sign],
        instr.text,
        instr.distance,
        line.slice(instr.interval[0], instr.interval[1] + 1)
      ]);

      steps.at(-1)[0] = "destination";

      return {
        line,
        steps,
        distance: path.distance,
        time: path.time / 1000,
        ascend: path.ascend,
        descend: path.descend
      };
    }

    return {
      mode: modeId,
      provider: "graphhopper",
      draggable: false,

      getRoute: function (points, signal) {
        // GraphHopper Directions API documentation https://docs.graphhopper.com
        const query = new URLSearchParams({
          profile: vehicleType,
          locale: OSM.i18n.locale,
          key: "7cb4eb19-e0f4-40a3-a5e0-f2c039366f32",
          elevation: false,
          instructions: true
        });
        const demoQuery = new URLSearchParams({ profile });

        for (const { lat, lng } of points) {
          query.append("point", [lat, lng]);
          demoQuery.append("point", [lat, lng]);
        }

        const meta = {
          credit: "GraphHopper",
          creditlink: "https://www.graphhopper.com/",
          demolink: "https://graphhopper.com/maps/?" + demoQuery
        };

        return fetch(OSM.GRAPHHOPPER_URL + "?" + query, { signal })
          .then(response => response.json())
          .then(({ paths }) => {
            if (!paths || paths.length === 0) throw new Error();

            return { ..._processDirections(paths[0]), ...meta };
          });
      }
    };
  }

  OSM.Directions.addEngine(new GraphHopperEngine("car", "car", "car"), true);
  OSM.Directions.addEngine(new GraphHopperEngine("bicycle", "bike", "bike"), true);
  OSM.Directions.addEngine(new GraphHopperEngine("foot", "foot", "foot"), true);
}());
