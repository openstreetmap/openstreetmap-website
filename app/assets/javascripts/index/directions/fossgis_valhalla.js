(function () {
  function FOSSGISValhallaEngine(modeId, costing) {
    const INSTR_MAP = [
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
      "u-turn-right", // kUturnRight = 12;
      "u-turn-left", // kUturnLeft = 13;
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
      mode: modeId,
      provider: "fossgis_valhalla",
      creditline:
      "<a href='https://gis-ops.com/global-open-valhalla-server-online/' target='_blank'>Valhalla (FOSSGIS)</a>",
      draggable: false,

      getRoute: function (points, signal) {
        const query = new URLSearchParams({
          json: JSON.stringify({
            locations: points.map(function (p) {
              return { lat: p.lat, lon: p.lng, radius: 5 };
            }),
            costing: costing,
            directions_options: {
              units: "km",
              language: OSM.i18n.locale
            }
          })
        });
        return fetch(OSM.FOSSGIS_VALHALLA_URL + "?" + query, { signal })
          .then(response => response.json())
          .then(({ trip }) => {
            if (trip.status !== 0) throw new Error();
            return _processDirections(trip.legs);
          });
      }
    };
  }

  OSM.Directions.addEngine(new FOSSGISValhallaEngine("car", "auto"), true);
  OSM.Directions.addEngine(new FOSSGISValhallaEngine("bicycle", "bicycle"), true);
  OSM.Directions.addEngine(new FOSSGISValhallaEngine("foot", "pedestrian"), true);
}());
