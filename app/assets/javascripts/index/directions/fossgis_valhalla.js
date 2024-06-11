function FOSSGISValhallaEngine(id, costing) {
  var INSTR_MAP = [
    "straight", // kNone = 0;
    "start", // kStart = 1;
    "start", // kStartRight = 2;
    "start", // kStartLeft = 3;
    "destination", // kDestination = 4;
    "destination", // kDestinationRight = 5;
    "destination", // kDestinationLeft = 6;
    "straight", // kBecomes = 7;
    "straight", // kContinue = 8;
    "slight-right", // kSlightRight = 9;
    "right", // kRight = 10;
    "sharp-right", // kSharpRight = 11;
    "u-turn", // kUturnRight = 12;
    "u-turn", // kUturnLeft = 13;
    "sharp-left", // kSharpLeft = 14;
    "left", // kLeft = 15;
    "slight-left", // kSlightLeft = 16;
    "straight", // kRampStraight = 17;
    "exit-right", // kRampRight = 18;
    "exit-left", // kRampLeft = 19;
    "exit-right", // kExitRight = 20;
    "exit-left", // kExitLeft = 21;
    "straight", // kStayStraight = 22;
    "slight-right", // kStayRight = 23;
    "slight-left", // kStayLeft = 24;
    "merge-left", // kMerge = 25;
    "roundabout", // kRoundaboutEnter = 26;
    "roundabout", // kRoundaboutExit = 27;
    "ferry", // kFerryEnter = 28;
    "straight", // kFerryExit = 29;
    null, // kTransit = 30;
    null, // kTransitTransfer = 31;
    null, // kTransitRemainOn = 32;
    null, // kTransitConnectionStart = 33;
    null, // kTransitConnectionTransfer = 34;
    null, // kTransitConnectionDestination = 35;
    null, // kPostTransitConnectionDestination = 36;
    "merge-right", // kMergeRight = 37;
    "merge-left" // kMergeLeft = 38;
  ];

  return {
    id: id,
    creditline:
      "<a href='https://gis-ops.com/global-open-valhalla-server-online/' target='_blank'>Valhalla (FOSSGIS)</a>",
    draggable: false,

    getRoute: function (points, callback) {
      return $.ajax({
        url: OSM.FOSSGIS_VALHALLA_URL,
        data: {
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
        },
        dataType: "json",
        success: function (data) {
          var trip = data.trip;

          if (trip.status === 0) {
            var line = [];
            var steps = [];
            var distance = 0;
            var time = 0;

            trip.legs.forEach(function (leg) {
              var legLine = L.PolylineUtil.decode(leg.shape, {
                precision: 6
              });

              line = line.concat(legLine);

              leg.maneuvers.forEach(function (manoeuvre, idx) {
                var point = legLine[manoeuvre.begin_shape_index];

                steps.push([
                  { lat: point[0], lng: point[1] },
                  INSTR_MAP[manoeuvre.type],
                  "<b>" + (idx + 1) + ".</b> " + manoeuvre.instruction,
                  manoeuvre.length * 1000,
                  []
                ]);
              });

              distance = distance + leg.summary.length;
              time = time + leg.summary.time;
            });

            callback(false, {
              line: line,
              steps: steps,
              distance: distance * 1000,
              time: time
            });
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
