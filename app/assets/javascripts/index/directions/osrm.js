// OSRM car engine
// Doesn't yet support hints

function OSRMEngine() {
  var previousPoints, hintData;

  return {
    id: "osrm_car",
    creditline: '<a href="http://project-osrm.org/" target="_blank">OSRM</a>',
    draggable: true,

    getRoute: function (points, callback) {
      var TURN_INSTRUCTIONS = [
        "",
        'javascripts.directions.instructions.continue',         // 1
        'javascripts.directions.instructions.slight_right',     // 2
        'javascripts.directions.instructions.turn_right',       // 3
        'javascripts.directions.instructions.sharp_right',      // 4
        'javascripts.directions.instructions.uturn',            // 5
        'javascripts.directions.instructions.sharp_left',       // 6
        'javascripts.directions.instructions.turn_left',        // 7
        'javascripts.directions.instructions.slight_left',      // 8
        'javascripts.directions.instructions.via_point',        // 9
        'javascripts.directions.instructions.follow',           // 10
        'javascripts.directions.instructions.roundabout',       // 11
        'javascripts.directions.instructions.leave_roundabout', // 12
        'javascripts.directions.instructions.stay_roundabout',  // 13
        'javascripts.directions.instructions.start',            // 14
        'javascripts.directions.instructions.destination',      // 15
        'javascripts.directions.instructions.against_oneway',   // 16
        'javascripts.directions.instructions.end_oneway',       // 17
        'javascripts.directions.instructions.ferry'             // 18
      ];

      var params = [
        { name: "z", value: "14" },
        { name: "output", value: "json" },
        { name: "instructions", value: true }
      ];

      for (var i = 0; i < points.length; i++) {
        params.push({ name: "loc", value: points[i].lat + "," + points[i].lng });

        if (hintData && previousPoints && previousPoints[i].equals(points[i])) {
          params.push({ name: "hint", value: hintData.locations[i] });
        }
      }

      if (hintData && hintData.checksum) {
        params.push({ name: "checksum", value: hintData.checksum });
      }

      return $.ajax({
        url: document.location.protocol + OSM.OSRM_URL,
        data: params,
        dataType: "json",
        success: function (data) {
          if (data.status === 207)
            return callback(true);

          previousPoints = points;
          hintData = data.hint_data;

          var line = L.PolylineUtil.decode(data.route_geometry, {
            precision: 6
          });

          var steps = [];
          for (i = 0; i < data.route_instructions.length; i++) {
            var s = data.route_instructions[i];
            var linesegend;
            var instCodes = s[0].split('-');
            if (s[8] === 2) {
              /* indicates a ferry in car routing mode, see https://github.com/Project-OSRM/osrm-backend/blob/6cbbd1e5a1b441eb27055f56956e1bac14832a58/profiles/car.lua#L151 */
              instCodes = ["18"];
            }
            var instText = "<b>" + (i + 1) + ".</b> ";
            var name = s[1] ? "<b>" + s[1] + "</b>" : I18n.t('javascripts.directions.instructions.unnamed');
            if (instCodes[0] === "11" && instCodes[1]) {
              instText += I18n.t(TURN_INSTRUCTIONS[instCodes[0]] + '_with_exit', { exit: instCodes[1], name: name } );
            } else {
              instText += I18n.t(TURN_INSTRUCTIONS[instCodes[0]] + '_without_exit', { name: name });
            }
            if ((i + 1) < data.route_instructions.length) {
              linesegend = data.route_instructions[i + 1][3] + 1;
            } else {
              linesegend = s[3] + 1;
            }
            steps.push([line[s[3]], instCodes[0], instText, s[2], line.slice(s[3], linesegend)]);
          }

          callback(false, {
            line: line,
            steps: steps,
            distance: data.route_summary.total_distance,
            time: data.route_summary.total_time
          });
        },
        error: function () {
          callback(true);
        }
      });
    }
  };
}

OSM.Directions.addEngine(new OSRMEngine(), true);
