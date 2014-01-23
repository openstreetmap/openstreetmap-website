// GraphHopper bicycle engine

OSM.RoutingEngines.list.push({    
    name: 'Bicycle (GraphHopper)',
    draggable: true,
    _hints: {},
    getRoute: function(final, points) {
        var url = "http://graphhopper.com/routing/api/route?vehicle=bike&locale=en";
        for (var i = 0; i < points.length; i++) {
            var pair = points[i].join(',');
            url += "&point=" + pair;
        }
        if (final)
            url += "&instructions=true";
        this.requestJSONP(url + "&type=jsonp&callback=");
    },
    gotRoute: function(router, data) {
        if (!data.info.routeFound) {
            alert("Couldn't find route between those two places");
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
