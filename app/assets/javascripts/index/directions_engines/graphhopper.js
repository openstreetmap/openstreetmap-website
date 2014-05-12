GraphHopperEngine = function (vehicleName, vehicleParam, locale) {
  this.vehicleName = vehicleName;
  this.vehicleParam = vehicleParam;
  //At this point the local system isn't correctly initialised yet, so we don't have accurate information about current locale
  this.locale = locale;
  if (!locale)
    this.locale = "en";
};

GraphHopperEngine.prototype.createConfig = function () {
  var that = this;
  return {
    name: "javascripts.directions.engines.graphhopper_" + this.vehicleName.toLowerCase(),
    creditline: '<a href="http://graphhopper.com/" target="_blank">Graphhopper</a>',
    draggable: false,
    _hints: {},

    getRoute: function (isFinal, points) {
      // documentation
      // https://github.com/graphhopper/graphhopper/blob/master/docs/web/api-doc.md
      var url = "http://graphhopper.com/api/1/route?"
        + that.vehicleParam
        + "&locale=" + I18n.currentLocale()
        + "&key=LijBPDQGfu7Iiq80w3HzwB4RUDJbMbhs6BU0dEnn";

      for (var i = 0; i < points.length; i++) {
        var pair = points[i].join(',');
        url += "&point=" + pair;
      }
      if (isFinal)
        url += "&instructions=true";
      // GraphHopper supports json too
      this.requestJSONP(url + "&type=jsonp&callback=");
    },

    gotRoute: function (router, data) {
      if (!data.paths || data.paths.length == 0)
        return false;

      // Draw polyline
      var path = data.paths[0];
      var line = L.PolylineUtil.decode(path.points);
      router.setPolyline(line);
      // Assemble instructions
      var steps = [];
      var len = path.instructions.length;
      for (i = 0; i < len; i++) {
        var instr = path.instructions[i];
        var instrCode = (i === len - 1) ? 15 : this.GH_INSTR_MAP[instr.sign];
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
      router.setItinerary({ steps: steps, distance: path.distance, time: path.time / 1000 });
      return true;
    },

    GH_INSTR_MAP: {
      "-3": 6, // sharp left
      "-2": 7, // left
      "-1": 8, // slight left
      0: 0, // straight
      1: 1, // slight right
      2: 2, // right
      3: 3, // sharp right
      4: -1, // finish reached
      5: -1 // via reached
    }
  };
};

OSM.DirectionsEngines.add(false, new GraphHopperEngine("Bicycle", "vehicle=bike").createConfig());
OSM.DirectionsEngines.add(false, new GraphHopperEngine("Foot", "vehicle=foot").createConfig());
