function loc_errHandler(error) 
{
    // fail quietly
    // we can't rely on this being called, the current FF geolocation UI is confusing.
    var c = new OpenLayers.LonLat(0, 20);
    setMapCenter(c, 1);
}

function loc_posHandler(position) 
{
    var c = new OpenLayers.LonLat(position.coords.longitude, position.coords.latitude);
    setMapCenter(c, 12);
}

var options = {
    timeout: 10000 
}

function locate_user() 
{
    if(navigator.geolocation)
    {
        navigator.geolocation.getCurrentPosition(loc_posHandler,loc_errHandler,options);
    }
}
