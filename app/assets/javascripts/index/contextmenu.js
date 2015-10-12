  var context_describe = function(e, map){
    var precision = OSM.zoomPrecision(map.getZoom()),
      latlng = e.latlng.wrap(),
      lat = latlng.lat.toFixed(precision),
      lng = latlng.lng.toFixed(precision);
    OSM.router.route("/search?query=" + encodeURIComponent(lat + "," + lng));
  };

  var context_directionsfrom = function(e, map){
    var precision = OSM.zoomPrecision(map.getZoom()),
      latlng = e.latlng.wrap(),
      lat = latlng.lat.toFixed(precision),
      lng = latlng.lng.toFixed(precision);
    OSM.router.route("/directions?" + querystring.stringify({
      route: lat + ',' + lng + ';' + $('#route_to').val()
    }));
  };

  var context_directionsto = function(e, map){
    var precision = OSM.zoomPrecision(map.getZoom()),
      latlng = e.latlng.wrap(),
      lat = latlng.lat.toFixed(precision),
      lng = latlng.lng.toFixed(precision);
    OSM.router.route("/directions?" + querystring.stringify({
      route: $('#route_from').val() + ';' + lat + ',' + lng
    }));
  };

  var context_addnote = function(e, map){
    // I'd like this, instead of panning, to pass a query parameter about where to place the marker
    map.panTo(e.latlng.wrap(), {animate: false});
    OSM.router.route('/note/new');
  };

  var context_centrehere = function(e, map){
    map.panTo(e.latlng);
  };

  var context_queryhere = function(e, map) {
    var precision = OSM.zoomPrecision(map.getZoom()),
      latlng = e.latlng.wrap(),
      lat = latlng.lat.toFixed(precision),
      lng = latlng.lng.toFixed(precision);
    OSM.router.route("/query?lat=" + lat + "&lon=" + lng);
  };

