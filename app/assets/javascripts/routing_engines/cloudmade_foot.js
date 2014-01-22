// CloudMade foot engine
// *** again, this should be shared from a Cloudmade library somewhere
// *** this API key is taken from some example code, not for real live use!

OSM.RoutingEngines.list.push({
	name: 'Foot (CloudMade)',
	draggable: true,
	getRoute: function(final,points) {
		var url="http://routes.cloudmade.com/8ee2a50541944fb9bcedded5165f09d9/api/0.3/";
		var p=[];
		for (var i=0; i<points.length; i++) {
			p.push(points[i][0]);
			p.push(points[i][1]);
		}
		url+=p.join(',');
		url+="/foot.js";
		this.requestJSONP(url+"?callback=");
	},
	gotRoute: function(data) {
		console.log(data);
		// *** todo
		// *** will require some degree of refactoring because instruction text is pre-assembled
		// *** otherwise largely like OSRM (funny that)
	}
});

