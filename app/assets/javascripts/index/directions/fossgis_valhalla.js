(function () {
  function FOSSGISValhallaEngine(id, costing) {
    const INSTR_MAP = [
      0, // kNone = 0;
      8, // kStart = 1;
      8, // kStartRight = 2;
      8, // kStartLeft = 3;
      14, // kDestination = 4;
      14, // kDestinationRight = 5;
      14, // kDestinationLeft = 6;
      0, // kBecomes = 7;
      0, // kContinue = 8;
      1, // kSlightRight = 9;
      2, // kRight = 10;
      3, // kSharpRight = 11;
      4, // kUturnRight = 12;
      4, // kUturnLeft = 13;
      7, // kSharpLeft = 14;
      6, // kLeft = 15;
      5, // kSlightLeft = 16;
      0, // kRampStraight = 17;
      24, // kRampRight = 18;
      25, // kRampLeft = 19;
      24, // kExitRight = 20;
      25, // kExitLeft = 21;
      0, // kStayStraight = 22;
      1, // kStayRight = 23;
      5, // kStayLeft = 24;
      20, // kMerge = 25;
      10, // kRoundaboutEnter = 26;
      10, // kRoundaboutExit = 27;
      17, // kFerryEnter = 28;
      0, // kFerryExit = 29;
      null, // kTransit = 30;
      null, // kTransitTransfer = 31;
      null, // kTransitRemainOn = 32;
      null, // kTransitConnectionStart = 33;
      null, // kTransitConnectionTransfer = 34;
      null, // kTransitConnectionDestination = 35;
      null, // kPostTransitConnectionDestination = 36;
      21, // kMergeRight = 37;
      20 // kMergeLeft = 38;
    ];

    function _processDirections(tripLegs) {
      let line = [];
      let steps = [];
      let distance = 0;
      let time = 0;

      for (const leg of tripLegs) {
        const legLine = L.PolylineUtil.decode(leg.shape, {
          precision: 6
        });

        const legSteps = leg.maneuvers.map(function (manoeuvre, idx) {
          const num = `<b>${idx + 1}.</b> `;
          const lineseg = legLine
            .slice(manoeuvre.begin_shape_index, manoeuvre.end_shape_index + 1)
            .map(([lat, lng]) => ({ lat, lng }));
          return [
            lineseg[0],
            INSTR_MAP[manoeuvre.type],
            num + manoeuvre.instruction,
            manoeuvre.length * 1000,
            lineseg
          ];
        });

        line = line.concat(legLine);
        steps = steps.concat(legSteps);
        distance += leg.summary.length;
        time += leg.summary.time;
      }

      return {
        line: line,
        steps: steps,
        distance: distance * 1000,
        time: time
      };
    }

    return {
      id: id,
      creditline:
      "<a href='https://gis-ops.com/global-open-valhalla-server-online/' target='_blank'>Valhalla (FOSSGIS)</a>",
      draggable: false,

      getRoute: function (points, callback) {
        const data = {
          json: JSON.stringify({
            locations: points.map(function (p) {
              return { lat: p.lat, lon: p.lng, radius: 5 };
            }),
            costing: costing,
            directions_options: {
              units: "km",
              language: I18n.currentLocale()
            }
          })
        };
        return $.ajax({
          url: OSM.FOSSGIS_VALHALLA_URL,
          data,
          dataType: "json",
          success: function ({ trip }) {
            if (trip.status === 0) {
              callback(false, _processDirections(trip.legs));
            } else {
              callback(true);
            }
          },
          error: function () {
            callback(true);
          }
        });
      }
    };
  }

  OSM.Directions.addEngine(new FOSSGISValhallaEngine("fossgis_valhalla_car", "auto"), true);
  OSM.Directions.addEngine(new FOSSGISValhallaEngine("fossgis_valhalla_bicycle", "bicycle"), true);
  OSM.Directions.addEngine(new FOSSGISValhallaEngine("fossgis_valhalla_foot", "pedestrian"), true);
}());
