// see: 
// http://developer.mapquest.com/web/products/open/directions-service
// http://open.mapquestapi.com/directions/
// https://github.com/apmon/openstreetmap-website/blob/21edc353a4558006f0ce23f5ec3930be6a7d4c8b/app/controllers/routing_controller.rb#L153

MapQuestEngine = function(vehicleName, vehicleParam, locale) {
    this.vehicleName = vehicleName;
    this.vehicleParam = vehicleParam;
    this.locale = locale;
    if (!locale)
        this.locale = "en";
};

MapQuestEngine.prototype.createConfig = function() {
    var that = this;
    return {
		name: "javascripts.directions.engines.mapquest_"+this.vehicleName.toLowerCase(),
		creditline: 'Directions courtesy of <a href="http://www.mapquest.com/" target="_blank">MapQuest</a> <img src="http://developer.mapquest.com/content/osm/mq_logo.png">',
		draggable: false,
		_hints: {},
		MQ_SPRITE_MAP: {
			0: 1, // straight
			1: 2, // slight right
			2: 3, // right
			3: 4, // sharp right
			4: 5, // reverse
			5: 6, // sharp left
			6: 7, // left
			7: 8, // slight left
			8: 5, // right U-turn
			9: 5, // left U-turn
			10: 2, // right merge
			11: 8, // left merge
			12: 2, // right on-ramp
			13: 8, // left on-ramp
			14: 2, // right off-ramp
			15: 8, // left off-ramp
			16: 2, // right fork
			17: 8, // left fork
			18: 1  // straight fork
		},
		getRoute: function(isFinal,points) {
			var url="http://open.mapquestapi.com/directions/v2/route?key=Fmjtd%7Cluur290anu%2Crl%3Do5-908a0y";
			var from=points[0]; var to=points[points.length-1];
			url+="&from="+from.join(',');
			url+="&to="+to.join(',');
			url+="&"+that.vehicleParam;
			//url+="&locale=" + I18n.currentLocale(); //Doesn't actually work. MapQuest requires full locale e.g. "de_DE", but I18n only provides language, e.g. "de"
			url+="&manMaps=false";
			url+="&shapeFormat=raw&generalize=0";
			this.requestCORS(url);
		},
		gotRoute: function(router,data) {
			if (data.info.statuscode!=0) return false;
		
			var poly=[];
			var shape=data.route.shape.shapePoints;
			for (var i=0; i<shape.length; i+=2) {
				poly.push(L.latLng(shape[i],shape[i+1]));
			}
			router.setPolyline(poly);

			// data.shape.maneuverIndexes links turns to polyline positions
			// data.legs[0].maneuvers is list of turns
			var steps=[];
			var mq=data.route.legs[0].maneuvers;
			for (var i=0; i<mq.length; i++) {
				var s=mq[i];
				var d=(i==mq.length-1) ? 15: this.MQ_SPRITE_MAP[s.turnType];
				steps.push([L.latLng(s.startPoint.lat, s.startPoint.lng), d, s.narrative, s.distance*1000]);
			}
			router.setItinerary( { steps: steps });
			return true;
		}
	};
};

OSM.RoutingEngines.list.push(new MapQuestEngine("Bicycle", "routeType=bicycle").createConfig());
OSM.RoutingEngines.list.push(new MapQuestEngine("Foot", "routeType=pedestrian").createConfig());
OSM.RoutingEngines.list.push(new MapQuestEngine("Car", "routeType=fastest").createConfig());
// can be: routeType=fastest|shortest|pedestrian|multimodal|bicycle
