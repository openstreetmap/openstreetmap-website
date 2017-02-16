function GraphHopperEngine(id, vehicleType) {
  var GH_INSTR_MAP = {
    "-3": 7, // sharp left
    "-2": 6, // left
    "-1": 5, // slight left
    0: 0, // straight
    1: 1, // slight right
    2: 2, // right
    3: 3, // sharp right
    4: 14, // finish reached
    5: 14, // via reached
    6: 10 // roundabout
  };

  return {
    id: id,
    creditline: '<a href="https://graphhopper.com/" target="_blank">Graphhopper</a>',
    draggable: false,

    getRoute: function (points, callback) {
      // GraphHopper Directions API documentation
      // https://github.com/graphhopper/directions-api/blob/master/docs-routing.md
      return $.ajax({
        url: document.location.protocol + OSM.GRAPHHOPPER_URL,
        data: {
          vehicle: vehicleType,
          locale: I18n.currentLocale(),
          key: "LijBPDQGfu7Iiq80w3HzwB4RUDJbMbhs6BU0dEnn",
          type: "jsonp",
          elevation: false,
          instructions: true,
          point: points.map(function (p) { return p.lat + "," + p.lng; })
        },
        traditional: true,
        dataType: "jsonp",
        success: function (data) {
          if (!data.paths || data.paths.length === 0)
            return callback(true);

          var path = data.paths[0];
          var line = L.PolylineUtil.decode(path.points);

          var steps = [];
          var len = path.instructions.length;
          for (var i = 0; i < len; i++) {
            var instr = path.instructions[i];
            var instrCode = (i === len - 1) ? 14 : GH_INSTR_MAP[instr.sign];
            var instrText = "<b>" + (i + 1) + ".</b> ";
            instrText += instr.text;
            var latLng = line[instr.interval[0]];
            var distInMeter = instr.distance;
            steps.push([
              {lat: latLng.lat, lng: latLng.lng},
              instrCode,
              instrText,
              distInMeter,
              []
            ]); // TODO does graphhopper map instructions onto line indices?
          }

          callback(false, {
            line: line,
            steps: steps,
            distance: path.distance,
            time: path.time / 1000,
            ascend: path.ascend,
            descend: path.descend
          });
        },
        error: function () {
          callback(true);
        }
      });
    }
  };
}

OSM.Directions.addEngine(new GraphHopperEngine("graphhopper_bicycle", "bike"), true);
OSM.Directions.addEngine(new GraphHopperEngine("graphhopper_foot", "foot"), true);
