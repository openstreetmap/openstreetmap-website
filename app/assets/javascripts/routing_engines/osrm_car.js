// OSRM car engine
// *** this should all be shared from an OSRM library somewhere
// *** need to clear hints at some point

OSM.RoutingEngines.list.push({
	name: "javascripts.directions.engines.osrm_car",
	creditline: 'Directions courtesy of <a href="http://project-osrm.org/" target="_blank">OSRM</a>',
	draggable: true,
	_hints: {},
	getRoute: function(isFinal,points) {
		var url="http://router.project-osrm.org/viaroute?z=14&output=json";
		for (var i=0; i<points.length; i++) {
			var pair=points[i].join(',');
			url+="&loc="+pair;
			if (this._hints[pair]) url+= "&hint="+this._hints[pair];
		}
		if (isFinal) url+="&instructions=true";
		this.requestJSONP(url+"&jsonp=");
	},
	gotRoute: function(router,data) {
		if (data.status==207) {
			alert("Couldn't find route between those two places");
			return false;
		}
		// Draw polyline
		var line=L.PolylineUtil.decode(data.route_geometry);
		for (i=0; i<line.length; i++) { line[i].lat/=10; line[i].lng/=10; }
		router.setPolyline(line);
		// *** store hints
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
		if (steps.length) router.setItinerary({ steps: steps });
	}
});
