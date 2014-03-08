// GraphHopper bicycle engine

OSM.RoutingEngines.list.push({    
    name: "javascripts.directions.engines.graphhopper_bike",
    creditline: 'Directions courtesy of <a href="http://graphhopper.com/routing/" target="_blank">Graphhopper</a>',
    draggable: true,
    _hints: {},
    getRoute: function(isFinal, points) {
        var url = "http://graphhopper.com/routing/api/route?vehicle=bike&locale=" + I18n.currentLocale();
        for (var i = 0; i < points.length; i++) {
            var pair = points[i].join(',');
            url += "&point=" + pair;
        }
        if (isFinal)
            url += "&instructions=true";
        this.requestJSONP(url + "&type=jsonp&callback=");
    },
    gotRoute: function(router, data) {
        if (!data.info.routeFound) {
            return false;
        }
        // Draw polyline
        var line = L.PolylineUtil.decode(data.route.coordinates);
        router.setPolyline(line);
        // Assemble instructions
        var steps = [];
        var instr = data.route.instructions;
        for (i = 0; i < instr.descriptions.length; i++) {
            var indi = instr.indications[i];
            var instrCode = (i==instr.descriptions.length-1) ? 15 : this.GH_INSTR_MAP[indi];
            var instrText = "<b>" + (i + 1) + ".</b> ";
            instrText += instr.descriptions[i];
            var latlng = instr.latLngs[i];
            var distInMeter = instr.distances[i];            
            steps.push([{lat: latlng[0], lng: latlng[1]}, instrCode, instrText, distInMeter]);
        }
        router.setItinerary({steps: steps});
        return true;
    },
    GH_INSTR_MAP: {
        "-3": 6, // sharp left
        "-2": 7, // left	
        "-1": 8, // slight left                
        0: 0, // straight
        1: 1, // slight right
        2: 2, // right
        3: 3 // sharp right		
    }
});
