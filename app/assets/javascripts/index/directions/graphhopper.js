(function () {
  function GraphHopperEngine(modeId, vehicleType) {
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

      const steps = path.instructions.map(function (instr, i) {
        const num = `<b>${i + 1}.</b> `;
        const lineseg = line
          .slice(instr.interval[0], instr.interval[1] + 1)
          .map(([lat, lng]) => ({ lat, lng }));
        return [
          lineseg[0],
          GH_INSTR_MAP[instr.sign],
          num + instr.text,
          instr.distance,
          lineseg
        ]; // TODO does graphhopper map instructions onto line indices?
      });
      steps.at(-1)[1] = "destination";

      return {
        line: line,
        steps: steps,
        distance: path.distance,
        time: path.time / 1000,
        ascend: path.ascend,
        descend: path.descend
      };
    }

    return {
      mode: modeId,
      provider: "graphhopper",
      creditline: "<a href=\"https://www.graphhopper.com/\" target=\"_blank\">GraphHopper</a>",
      draggable: false,

      getRoute: function (points, signal) {
        // GraphHopper Directions API documentation
        // https://graphhopper.com/api/1/docs/routing/
        const query = new URLSearchParams({
          vehicle: vehicleType,
          locale: OSM.i18n.locale,
          key: "LijBPDQGfu7Iiq80w3HzwB4RUDJbMbhs6BU0dEnn",
          elevation: false,
          instructions: true,
          turn_costs: vehicleType === "car"
        });
        points.forEach(p => query.append("point", p.lat + "," + p.lng));
        return fetch(OSM.GRAPHHOPPER_URL + "?" + query, { signal })
          .then(response => response.json())
          .then(({ paths }) => {
            if (!paths || paths.length === 0) throw new Error();
            return _processDirections(paths[0]);
          });
      }
    };
  }

  OSM.Directions.addEngine(new GraphHopperEngine("car", "car"), true);
  OSM.Directions.addEngine(new GraphHopperEngine("bicycle", "bike"), true);
  OSM.Directions.addEngine(new GraphHopperEngine("foot", "foot"), true);
}());
