// CloudMade foot engine
// *** again, this should be shared from a Cloudmade library somewhere
// *** this API key is taken from some example code, not for real live use!
// http://cloudmade.com/documentation/routing

OSM.RoutingEngines.list.push({
	name: "javascripts.directions.engines.cloudmade_foot",
	creditline: 'Directions courtesy of <a href="http://cloudmade.com/products/routing" target="_blank">Cloudmade</a>',
	draggable: false,
	CM_SPRITE_MAP: {
		"C": 1,
		"TL": 7,
		"TSLL": 8,
		"TSHL": 6,
		"TR": 3,
		"TSLR": 2,
		"TSHR": 4,
		"TU": 5
	}, // was half expecting to see TLDR in there
	getRoute: function(isFinal,points) {
		var url="http://routes.cloudmade.com/8ee2a50541944fb9bcedded5165f09d9/api/0.3/";
		var p=[];
		for (var i=0; i<points.length; i++) {
			p.push(points[i][0]);
			p.push(points[i][1]);
		}
		url+=p.join(',');
		url+="/foot.js";
        url+="?lang=" + I18n.currentLocale();
		this.requestJSONP(url+"&callback=");
	},
	gotRoute: function(router,data) {
		router.setPolyline(data.route_geometry);
		// Assemble instructions
		var steps=[];
		for (i=0; i<data.route_instructions.length; i++) {
			var s=data.route_instructions[i];
			steps.push([data.route_geometry[s[2]], this.CM_SPRITE_MAP[s[7]], s[0], s[1]]);
		}
		router.setItinerary({ steps: steps });
	}
});

