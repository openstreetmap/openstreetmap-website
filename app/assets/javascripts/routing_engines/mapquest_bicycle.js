// see: 
// http://developer.mapquest.com/web/products/open/directions-service
// http://open.mapquestapi.com/directions/
// https://github.com/apmon/openstreetmap-website/blob/21edc353a4558006f0ce23f5ec3930be6a7d4c8b/app/controllers/routing_controller.rb#L153

// *** needs to give credit

OSM.RoutingEngines.list.push({
	name: 'Bicycle (MapQuest Open)',
	draggable: true,
	_hints: {},
	getRoute: function(final,points) {
		var url="http://open.mapquestapi.com/directions/v2/route?key=Fmjtd%7Cluur290anu%2Crl%3Do5-908a0y";
		var from=points[0]; var to=points[points.length-1];
		url+="&from="+from.join(',');
		url+="&to="+to.join(',');
		url+="&routeType=bicycle";
		url+="&manMaps=false";
		url+="&shapeFormat=raw&generalize=0";
		this.requestJSONP(url+"&callback=");
	},
	gotRoute: function(router,data) {
		var poly=[];
		var shape=data.route.shape.shapePoints;
		for (var i=0; i<shape.length; i+=2) {
			poly.push(L.latLng(shape[i],shape[i+1]));
		}
		router.setPolyline(poly);

		// data.shape.maneuverIndexes links turns to polyline positions
		// data.legs[0].maneuvers is list of turns
		console.log(data);
//		router.setItinerary(data.route_instructions);
	}
});
