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
      steps.at(-1)[1] = 14;

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
      id: id,
      creditline: "<a href=\"https://www.graphhopper.com/\" target=\"_blank\">GraphHopper</a>",
      draggable: false,

      getRoute: function (points, callback) {
        // GraphHopper Directions API documentation
        // https://graphhopper.com/api/1/docs/routing/
        const data = {
          vehicle: vehicleType,
          locale: I18n.currentLocale(),
          key: "LijBPDQGfu7Iiq80w3HzwB4RUDJbMbhs6BU0dEnn",
          elevation: false,
          instructions: true,
          turn_costs: vehicleType === "car",
          point: points.map(p => p.lat + "," + p.lng)
        };
        return $.ajax({
          url: OSM.GRAPHHOPPER_URL,
          data,
          traditional: true,
          dataType: "json",
          success: function ({ paths }) {
            if (!paths || paths.length === 0) {
              return callback(true);
            }
            callback(false, _processDirections(paths[0]));
          },
          error: function () {
            callback(true);
          }
        });
      }
    };
  }

  OSM.Directions.addEngine(new GraphHopperEngine("graphhopper_car", "car"), true);
  OSM.Directions.addEngine(new GraphHopperEngine("graphhopper_bicycle", "bike"), true);
  OSM.Directions.addEngine(new GraphHopperEngine("graphhopper_foot", "foot"), true);
}());
