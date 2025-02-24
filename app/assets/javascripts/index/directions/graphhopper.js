(function () {
  function GraphHopperEngine(id, vehicleType) {
    const GH_INSTR_MAP = {
      "-3": 7, // sharp left
      "-2": 6, // left
      "-1": 5, // slight left
      "0": 0, // straight
      "1": 1, // slight right
      "2": 2, // right
      "3": 3, // sharp right
      "4": 14, // finish reached
      "5": 14, // via reached
      "6": 10, // roundabout
      "-7": 19, // keep left
      "7": 18, // keep right
      "-98": 4, // unknown direction u-turn
      "-8": 4, // left u-turn
      "8": 4 // right u-turn
    };

    function _processDirections(path) {
      const line = L.PolylineUtil.decode(path.points);

      const legs = path.instructions
        .reduce((parts, instr) => {
          parts.at(-1).push(instr);
          if (!instr.distance && !instr.time && instr.interval[1] !== line.length - 1) {
            parts.push([]);
          }
          return parts;
        }, [[]])
        .map(function (steps) {
          const out = steps.map(mapInstructions);
          out.at(-1)[1] = 14;
          return out;
        });

      function mapInstructions(instr, i) {
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
        ];
      }

      return {
        line,
        legs,
        distance: path.distance,
        time: path.time / 1000,
        ascend: path.ascend,
        descend: path.descend
      };
    }

    return {
      id: id,
      creditline: "<a href=\"https://www.graphhopper.com/\" target=\"_blank\">GraphHopper</a>",
      draggable: false,

      getRoute: function (points, signal) {
        // GraphHopper Directions API documentation
        // https://graphhopper.com/api/1/docs/routing/
        const query = new URLSearchParams({
          vehicle: vehicleType,
          locale: I18n.currentLocale(),
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

  OSM.Directions.addEngine(new GraphHopperEngine("graphhopper_car", "car"), true);
  OSM.Directions.addEngine(new GraphHopperEngine("graphhopper_bicycle", "bike"), true);
  OSM.Directions.addEngine(new GraphHopperEngine("graphhopper_foot", "foot"), true);
}());
