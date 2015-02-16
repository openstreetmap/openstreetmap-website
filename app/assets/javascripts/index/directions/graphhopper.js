function GraphHopperEngine(id, vehicleParam) {
  var GH_INSTR_MAP = {
    "-3": 6, // sharp left
    "-2": 7, // left
    "-1": 8, // slight left
    0: 0, // straight
    1: 1, // slight right
    2: 2, // right
    3: 3, // sharp right
    4: -1, // finish reached
    5: -1 // via reached
  };

  return {
    id: id,
    creditline: '<a href="https://graphhopper.com/" target="_blank">Graphhopper</a>',
    draggable: false,

    getRoute: function (points, callback) {
      // documentation
      // https://github.com/graphhopper/graphhopper/blob/master/docs/web/api-doc.md
      var url = document.location.protocol + "//graphhopper.com/api/1/route?"
        + vehicleParam
        + "&locale=" + I18n.currentLocale()
        + "&key=LijBPDQGfu7Iiq80w3HzwB4RUDJbMbhs6BU0dEnn"
        + "&type=jsonp"
        + "&instructions=true";

      for (var i = 0; i < points.length; i++) {
        url += "&point=" + points[i].lat + ',' + points[i].lng;
      }

      $.ajax({
        url: url,
        dataType: 'jsonp',
        success: function (data) {
          if (!data.paths || data.paths.length == 0)
            return callback(true);

          var path = data.paths[0];
          var line = L.PolylineUtil.decode(path.points);

          var steps = [];
          var len = path.instructions.length;
          for (var i = 0; i < len; i++) {
            var instr = path.instructions[i];
            var instrCode = (i === len - 1) ? 15 : GH_INSTR_MAP[instr.sign];
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

          callback(null, {
            line: line,
            steps: steps,
            distance: path.distance,
            time: path.time / 1000
          });
        }
      });
    }
  };
}

OSM.Directions.addEngine(GraphHopperEngine("graphhopper_bicycle", "vehicle=bike"), true);
OSM.Directions.addEngine(GraphHopperEngine("graphhopper_foot", "vehicle=foot"), true);
