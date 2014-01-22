// OSRM car engine
// *** this should all be shared from an OSRM library somewhere
// *** need to clear hints at some point

OSM.RoutingEngines.list.push({
	name: 'Car (OSRM)',
	draggable: true,
	_hints: {},
	getRoute: function(final,points) {
		var url="http://router.project-osrm.org/viaroute?z=14&output=json";
		for (var i=0; i<points.length; i++) {
			var pair=points[i].join(',');
			url+="&loc="+pair;
			if (this._hints[pair]) url+= "&hint="+this._hints[pair];
		}
		if (final) url+="&instructions=true";
		this.requestJSONP(url+"&jsonp=");
	},
	gotRoute: function(router,data) {
		if (data.status==207) {
			alert("Couldn't find route between those two places");
			return false;
		}
		// *** store hints
		var line=L.PolylineUtil.decode(data.route_geometry);
		for (i=0; i<line.length; i++) { line[i].lat/=10; line[i].lng/=10; }
		router.setPolyline(line);
		router.setItinerary(data.route_instructions);
	}
});
