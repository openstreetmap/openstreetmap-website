// OSRM car engine
// Doesn't yet support hints

OSRMEngine = function(vehicleName, baseURL, locale) {
    this.vehicleName = vehicleName;
    this.baseURL = baseURL;
    this.locale = locale;
    if (!locale)
        this.locale = "en";
};

OSRMEngine.prototype.createConfig = function() {
    var that = this;
    return {
        name: "javascripts.directions.engines.osrm_"+this.vehicleName.toLowerCase(),
        creditline: 'Directions courtesy of <a href="http://project-osrm.org/" target="_blank">OSRM</a>',
        draggable: true,
        _hints: {},
        getRoute: function(isFinal,points) {
            var url=that.baseURL+"?z=14&output=json";
            for (var i=0; i<points.length; i++) {
                var pair=points[i].join(',');
                url+="&loc="+pair;
                if (this._hints[pair]) url+= "&hint="+this._hints[pair];
            }
            if (isFinal) url+="&instructions=true";
            this.requestCORS(url);
        },
        gotRoute: function(router,data) {
            if (data.status==207) {
                return false;
            }
            // Draw polyline
            var line=L.PolylineUtil.decode(data.route_geometry);
            for (i=0; i<line.length; i++) { line[i].lat/=10; line[i].lng/=10; }
            router.setPolyline(line);
            // Assemble instructions
            var steps=[];
            for (i=0; i<data.route_instructions.length; i++) {
                var s=data.route_instructions[i];
                var instCodes=s[0].split('-');
                var instText="<b>"+(i+1)+".</b> ";
                instText+=TURN_INSTRUCTIONS[instCodes[0]];
                if (instCodes[1]) { instText+="exit "+instCodes[1]+" "; }
                if (instCodes[0]!=15) { instText+=s[1] ? "<b>"+s[1]+"</b>" : I18n.t('javascripts.directions.instructions.unnamed'); }
                steps.push([line[s[3]], s[0].split('-')[0], instText, s[2]]);
            }
            if (steps.length) router.setItinerary({ steps: steps, distance: data.route_summary.total_distance, time: data.route_summary.total_time });
            return true;
        }
    };
};

OSM.RoutingEngines.list.push(new OSRMEngine("Car", "http://router.project-osrm.org/viaroute").createConfig());
