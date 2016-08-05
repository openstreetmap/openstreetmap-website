function MapzenEngine(id, costing) {
  var MZ_INSTR_MAP = [
    0,  // kNone = 0;
    8, // kStart = 1;
    8, // kStartRight = 2;
    8, // kStartLeft = 3;
    14,  // kDestination = 4;
    14,  // kDestinationRight = 5;
    14,  // kDestinationLeft = 6;
    0,  // kBecomes = 7;
    0,  // kContinue = 8;
    1,  // kSlightRight = 9;
    2,  // kRight = 10;
    3,  // kSharpRight = 11;
    4,  // kUturnRight = 12;
    4,  // kUturnLeft = 13;
    7,  // kSharpLeft = 14;
    6,  // kLeft = 15;
    5,  // kSlightLeft = 16;
    0,  // kRampStraight = 17;
    2,  // kRampRight = 18;
    6,  // kRampLeft = 19;
    24, // kExitRight = 20;
    25, // kExitLeft = 21;
    0,  // kStayStraight = 22;
    2,  // kStayRight = 23;
    6,  // kStayLeft = 24;
    20, // kMerge = 25;
    10, // kRoundaboutEnter = 26;
    11, // kRoundaboutExit = 27;
    17, // kFerryEnter = 28;
    0   // kFerryExit = 29;
  ];

  return {
    id: id,
    creditline: "<a href='https://mapzen.com/projects/valhalla' target='_blank'>Mapzen</a>",
    draggable: false,

    getRoute: function (points, callback) {
      return $.ajax({
        url: document.location.protocol + OSM.MAPZEN_VALHALLA_URL,
        data: {
          api_key: OSM.MAPZEN_VALHALLA_KEY,
          json: JSON.stringify({
            locations: points.map(function (p) { return { lat: p.lat, lon: p.lng }; }),
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

              leg.maneuvers.forEach(function (manoeuvre) {
                var point = legLine[manoeuvre.begin_shape_index];

                steps.push([
                  { lat: point[0], lng: point[1] },
                  MZ_INSTR_MAP[manoeuvre.type],
                  manoeuvre.instruction,
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

if (OSM.MAPZEN_VALHALLA_KEY) {
  OSM.Directions.addEngine(new MapzenEngine("mapzen_car", "auto"), true);
  OSM.Directions.addEngine(new MapzenEngine("mapzen_bicycle", "bicycle"), true);
  OSM.Directions.addEngine(new MapzenEngine("mapzen_foot", "pedestrian"), true);
}
