function MapzenEngine(id, costing) {
  var MZ_INSTR_MAP = [
    1,  // kNone = 0;
    14, // kStart = 1;
    14, // kStartRight = 2;
    14, // kStartLeft = 3;
    15, // kDestination = 4;
    15, // kDestinationRight = 5;
    15, // kDestinationLeft = 6;
    1,  // kBecomes = 7;
    1,  // kContinue = 8;
    2,  // kSlightRight = 9;
    3,  // kRight = 10;
    4,  // kSharpRight = 11;
    5,  // kUturnRight = 12;
    5,  // kUturnLeft = 13;
    6,  // kSharpLeft = 14;
    7,  // kLeft = 15;
    8,  // kSlightLeft = 16;
    1,  // kRampStraight = 17;
    2,  // kRampRight = 18;
    8,  // kRampLeft = 19;
    2,  // kExitRight = 20;
    8,  // kExitLeft = 21;
    1,  // kStayStraight = 22;
    2,  // kStayRight = 23;
    8,  // kStayLeft = 24;
    1,  // kMerge = 25;
    11, // kRoundaboutEnter = 26;
    12, // kRoundaboutExit = 27;
    18, // kFerryEnter = 28;
    1   // kFerryExit = 29;
  ];

  return {
    id: id,
    creditline: "<a href='https://mapzen.com/projects/valhalla' target='_blank'>Mapzen</a>",
    draggable: false,

    getRoute: function (points, callback) {
      return $.ajax({
        url: document.location.protocol + "//valhalla.mapzen.com/route",
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
