// June 20th 2005 http://civicactions.net anselm@hook.org public domain version 0.5

//
// miscellaneous
//

var netscape = ( document.getElementById && !document.all ) || document.layers;
var defaultEngine = null; // xxx for firefox keyboard events.

var PI = 3.14159265358979323846;

var lat_range = PI, lon_range = PI;

//
// Utility - get div position - may not be accurate
//

function getCSSPositionX(parent) 
{
    var offset = parent.x ? parseInt(parent.x) : 0;
    offset += parent.style.left ? parseInt(parent.style.left) : 0;
    for(var node = parent; node ; node = node.offsetParent ) 
	{ 
		offset += node.offsetLeft; 
	}
    return offset;
}

function getCSSPositionY(parent) 
{
    var offset = parent.y ? parseInt(parent.y) : 0;
    offset += parent.style.top ? parseInt(parent.style.top) : 0;
    for(var node = parent; node ; node = node.offsetParent ) 
	{ 
		offset += node.offsetTop; 
	}
    return offset;
}

///
/// initialize a new tile engine object
/// usage: var engine = new tile_engine_new(parentdiv,stylehints,wmssource,lon,lat,zoom,optional width, optional height)
///
function tile_engine_new(parentname,hints,feedurl,url,lon,lat,zoom,w,h) 
{
    // NW geocoder removed for now

	this.timestamp = new Date().getTime();
	this.urlAttr = new Array();

    // NW Removed navigation buttons entirely for flexibility    

    this.lonPerPixel = function()
            { return (this.lon_quant/this.scale)/this.tilewidth; }

    this.latPerPixel = function()
            { return (this.lat_quant/this.scale)/this.tileheight; }

    this.xToLon = function(x)
            { return this.lon + (x-this.thewidth/2)*this.lonPerPixel(); } 

    this.yToLat = function(y)
            { return normallat(this.lat - (y-this.theheight/2)
                                *this.latPerPixel()); } 

	this.lonToX = function (lon)
			{ return ((lon-this.lon)/this.lonPerPixel()) + this.thewidth/2;}

	this.latToY = function(lat)
			{ return ((this.lat-mercatorlat(lat))/this.latPerPixel()) + 
							this.theheight/2; }


    //
    // it is possible that this collection is already in use - clean it
    //
    this.clean = function() 
    { 
		/*
        while( this.parent.hasChildNodes() ) 
            this.parent.removeChild( this.parent.firstChild );
			*/

		for(var ct=0; ct<this.parent.childNodes.length; ct++)
		{
			if(this.parent.childNodes[ct].id != "controls")
				this.parent.removeChild(this.parent.childNodes[ct]);
		}

        //
        // build inner tile container for theoretical speed improvement?
        // center in parent for simplicity of math
        // size of inner container is irrelevant since overflow is enabled
        //

        if( this.dragcontainer ) 
        {
            this.tiles = document.createElement('div');
            this.tiles.style.position = 'absolute';
            this.tiles.style.left = this.displaywidth/2 + 'px';
            this.tiles.style.top = this.displayheight/2 + 'px';
            this.tiles.style.width = '16px';
            this.tiles.style.height = '16px';
            if( this.debug ) 
            {
                this.tiles.style.border = 'dashed green 1px';
            }
            this.tiles.tile_engine = this;
            this.parent.appendChild(this.tiles);

        } 
        else 
        {
            this.tiles = this.parent;
        }
    }

    /// focus over specified lon/lat and zoom
    /// user should call this.drag(0,0) after this to force an initial refresh
    ///

    this.performzoom = function(lon,lat,z) 
    {
        // setup for zoom
        // this engine operates at * scale to try avoid tile errors thrashing 
        // server cache
        
        this.scale = 1000000;
        this.lon_min_clamp = -180 * this.scale;
        this.lon_max_clamp = 180 * this.scale;
        this.lat_min_clamp = -180 * this.scale; //t
        this.lat_max_clamp = 180 * this.scale; //t
        this.lon_start_tile = 180 * this.scale;
        this.lat_start_tile = 90 * this.scale; //t
        this.zoom_power = 2;
        this.lon_quant = this.lon_start_tile;
        this.lat_quant = this.lat_start_tile;
        this.lon = lon;
        this.lat = lat;

        // operational lat - = lat due to quirks in our engine and quirks in o
        // lon/lat design
        lat = -lat;

        // divide tile size until reach requested zoom
        // trying to guarantee consistency so as to not thrash the server side tile cache
        while(z > 0) 
        {
            this.lon_quant = this.lon_quant / this.zoom_power;
            this.lat_quant = this.lat_quant / this.zoom_power;
            z--;
        }
        this.lon_quant = Math.round( this.lon_quant );
        this.lat_quant = Math.round( this.lat_quant );
    
        // get user requested exact lon/lat
        this.lon_scaled = Math.round( lon * this.scale );
        this.lat_scaled = Math.round( lat * this.scale );
    


        // convert requested exact lon/lat to quantized lon lat (rounding down 
        // or up as best suits)
        this.lon_round = Math.round( this.lon_scaled / this.lon_quant ) * 
                this.lon_quant;
        this.lat_round = Math.round( this.lat_scaled / this.lat_quant ) * 
                this.lat_quant;
    
        //alert('lon_round=' + this.lon_round+ ' lat_round='+this.lat_round);

        // calculate world extents [ this is the span of all tiles in lon/lat ]
        this.lon_min = this.lon_round - this.lon_quant;
        this.lon_max = this.lon_round + this.lon_quant;
        this.lat_min = this.lat_round - this.lat_quant;
        this.lat_max = this.lat_round + this.lat_quant;
    
        // set tiled region details [ this is the span of all tiles in pixels ]
        this.centerx = 0;
        this.centery = 0;
        this.tilewidth = 256;
        this.tileheight = 128;
        this.left = -this.tilewidth;
        this.right = this.tilewidth;
        this.top = -this.tileheight;
        this.bot = this.tileheight;


        // adjust the current center position slightly to reflect exact lat/lon
        // not rounded
        this.centerx -= (this.lon_scaled-this.lon_round)/
            (this.lon_max-this.lon_min)*(this.right-this.left);
        this.centery -= (this.lat_scaled-this.lat_round)/
            (this.lat_max-this.lat_min)*(this.bot-this.top);
    }

	this.update_perma_link = function() {
		// because we're using mercator
		updatelinks(this.lon,normallat(this.lat),this.zoom);
	}

    ///
    /// draw the spanning lon/lat range
    /// drag is simply the mouse delta in pixels
    ///

    this.drag = function(dragx,dragy) 
    {
		var fred=true;

        // move the drag offset
        this.centerx += dragx;
        this.centery += dragy;

        // update where we think the user is actually focused
        this.lon = ( this.lon_round - ( this.lon_max - this.lon_min ) / 
            ( this.right - this.left ) * this.centerx ) / this.scale;
        this.lat = - ( this.lat_round - ( this.lat_max - this.lat_min ) / 
            ( this.bot - this.top ) * this.centery ) / this.scale;

		this.update_perma_link();

        // show it
        var helper = this.navhelp; 

         // extend exposed sections
        var dirty = false;
        while( this.left + this.centerx > -this.displaywidth/2 && 
                this.lon_min > this.lon_min_clamp ) 
        {
            this.left -= this.tilewidth;
            this.lon_min -= this.lon_quant;
            dirty = true;
        }
        while( this.right + this.centerx < this.displaywidth/2 && 
                this.lon_max < this.lon_max_clamp ) 
        {
            this.right += this.tilewidth;
            this.lon_max += this.lon_quant;
            dirty = true;
        }
        while( this.top + this.centery > -this.displayheight/2 && 
        this.lat_min > this.lat_min_clamp ) 
        {
            this.top -= this.tileheight;
            this.lat_min -= this.lat_quant;
            dirty = true;
        }

        while( this.bot + this.centery < this.displayheight/2 && 
        this.lat_max < this.lat_max_clamp ) 
        {
            this.bot += this.tileheight;
            this.lat_max += this.lat_quant;
            dirty = true;
        }


        // prepare to walk the container and assure that all nodes are correct
        var containerx;
        var containery;

        // in drag container mode we do not have to move the children all the 
        // time
        if( this.dragcontainer ) 
        {
            this.tiles.style.left = this.displaywidth / 2 + this.centerx + 'px';
            this.tiles.style.top = this.displayheight / 2 + this.centery + 'px';
            if( !dirty && this.tiles.hasChildNodes() ) 
            {
                return;
            }
            containerx = this.left;
            containery = this.top;
        } 
        else 
        {
            containerx = this.left + this.centerx;
            containery = this.top + this.centery;
        }

        // walk all tiles and repair as needed
        // xxx one bug is that it walks the _entire_ width and height... 
        // not just visible.
        // xxx this makes cleanup harder and perhaps a bitmap is better

        var removehidden = 1;
        var removecolumn = 0;
        var removerow = 0;
        var containeryreset = containery;

        for( var x = this.lon_min; x < this.lon_max ; x+= this.lon_quant ) 
        {
            // will this row be visible in the next round?
            if( removehidden ) 
            {
                var rx = containerx + this.centerx;
                if( rx > this.displaywidth / 2 ) 
                {
                    removerow = 1;
                    // ideally i would truncate max width here
                } 
                else if( rx + this.tilewidth < - this.displaywidth / 2 ) 
                {
                    removerow = 1;
                } 
                else 
                {
                    removerow = 0;
                }
            }

            for( var y = this.lat_min; y < this.lat_max ; y+= this.lat_quant ) 
            {
                // is this column visible?
                if( removehidden ) 
                {
                    var ry = containery + this.centery;
                    if( ry > this.displayheight / 2 ) 
                    {
                        removecolumn = 1;
                    } 
                    else if( ry + this.tileheight < - this.displayheight/2) 
                    {
                        removecolumn = 1;
                    } 
                    else 
                    {
                        removecolumn = 0;
                    }
                }

                // convert to WMS compliant coordinate system
                var lt = x / this.scale;
                var rt = lt + this.lon_quant / this.scale;
                var tp = y / this.scale;
                var bt = tp + this.lat_quant / this.scale;
                var temp = bt;
                var bt = -tp;
                var tp = -temp;

                // modify for mercator-projected tiles: 
                tp = 180/PI * (2 * Math.atan(Math.exp(tp * PI / 180)) - PI / 2);
                bt = 180/PI * (2 * Math.atan(Math.exp(bt * PI / 180)) - PI / 2);
                
                // make a key
                var key = this.url + "?WIDTH="+(this.tilewidth)+"&HEIGHT="+
                    (this.tileheight)+"&BBOX="+lt+","+tp+","+rt+","+bt;

                // see if our tile is already present
                var node = document.getElementById(key);

                // create if not present
                if(!node) 
                {
                    if( this.debug > 0) 
                    {
                        node = document.createElement('div');
                    } 
                    else 
                    {
                        node = document.createElement('img');
                    }
                    node.id = key;
                    node.className = 'tile';
                    node.style.position = 'absolute';
                    node.style.width = this.tilewidth + 'px';
                    node.style.height = this.tileheight + 'px';
                    node.style.left = containerx + 'px';
                    node.style.top = containery + 'px';
                    node.style.zIndex = 10; // to appear under the rss elements
                    node.tile_engine = this;
                    if( this.debug > 0) 
                    {
                        node.style.border = "1px solid yellow";
                        node.innerHTML = key;
                        if( this.debug > 1 ) 
                        {
                            var img = document.createElement('img');
                            img.src = key;
                            node.appendChild(img);
                        }
                    }

                    var goURL = key + "&zoom=" + this.zoom; 
							
				    for(var k in this.urlAttr) 
					{
						goURL += "&"+k+"="+this.urlAttr[k];
					}
				
					node.src = goURL;

                    node.alt = "loading tile..";
                    node.style.color = "#ffffff";
                    this.tiles.appendChild(node);
                }
                // adjust if using active style
                else if( !this.dragcontainer ) {
                    node.style.left = containerx + 'px';
                    node.style.top = containery + 'px';
                }

                containery += this.tileheight;
            }
            containery = containeryreset;
            containerx += this.tilewidth;
        }
    }

    this.zoomTo = function(zoom) 
    {

        this.zoom  = zoom;
    
        if (this.zoom < this.minzoom) { this.zoom = this.minzoom; }
        if (this.zoom > this.maxzoom) { this.zoom = this.maxzoom; }




        ///
        /// immediately draw and or fit to feed
        ///
        this.performzoom(this.lon,this.lat,zoom);
        this.drag(0,0);

        ///
    } // CLOSE ZOOM FUNCTION

    this.setLatLon = function(lat,lon)
    { 
        this.lon=lon; 
        this.lat=mercatorlat(lat); 
        this.clean(); 
        this.performzoom(lon,mercatorlat(lat),this.zoom);
        this.drag(0,0); 
    }

	this.forceRefresh = function()
	{
		this.clean();
        this.performzoom(this.lon,this.lat,this.zoom);
        this.drag(0,0); 
	}

    ///
    /// zoom a tile group
    ///
    this.tile_engine_zoomout = function() 
    {
        this.clean();
        this.zoomTo(this.zoom-1);

        return false; // or safari falls over
    }

    ///
    /// zoom a tile group
    ///
    this.tile_engine_zoomin = function() 
    {
        
        this.clean();
        this.zoomTo(this.zoom+1);
  
        return false; // or safari falls over
    }

    this.setURL=function(url) { this.url=url; }



    ///
    /// intercept context events to minimize out-of-browser interruptions
    ///
    
    this.event_context = function(e) 
    {
        return false;
    }

    ///
    /// keys
    ///

    this.event_key = function(e) 
    {
        var key = 0;        

        var hostengine = defaultEngine;

        if( window && window.event && window.event.srcElement ) {
            hostengine = window.event.srcElement.tile_engine;
        } else if( e.target ) {
            hostengine = e.target.tile_engine;
        } else if( e.srcElement ) {
            hostengine = e.srcElement.tile_engine;
        }

        if( hostengine == null ) {
            hostengine = defaultEngine;
            if( hostengine == null ) {
                return;
            }
        }


        if( e == null && document.all ) {
            e = window.event;
        }

        if( e ) {
            if( e.keyCode ) {
                key = e.keyCode;
            }
            else if( e.which ) {
                key = e.which;
            }

            switch(key) {
            case 97: // a = left
                hostengine.drag(16,0);
                break;
            case 100: // d = right
                hostengine.drag(-16,0);
                break;
            case 119: // w = up
                hostengine.drag(0,16);
                break;
            case 120: // x = dn
                hostengine.drag(0,-16);
                break;
            case 115: // s = center
                new tile_engine_new(hostengine.parentname,
                            "FULL",
                            hostengine.feedurl, // xxx hrm, cache this?
                            hostengine.url,
                            hostengine.lon,
                            hostengine.lat,
                            hostengine.zoom,
                            0,0
                            );
                break;
            case 122: // z = zoom
                new tile_engine_new(hostengine.parentname,
                            "FULL",
                            hostengine.feedurl, // xxx hrm, cache this?
                            hostengine.url,
                            hostengine.lon,
                            hostengine.lat,
                            hostengine.zoom + 1,
                            0,0
                            );
                break;
            case  99: // c = unzoom
                new tile_engine_new(hostengine.parentname,
                            "FULL",
                            hostengine.feedurl, // xxx hrm, cache this?
                            hostengine.url,
                            hostengine.lon,
                            hostengine.lat,
                            hostengine.zoom - 1,
                            0,0
                            );
                break;
            }
        }    
    }

    ///
    /// catch mouse move events
    /// this routine _must_ return false or else the operating system outside-of-browser-scope drag and drop handler will interfere
    ///

    this.event_mouse_move = function(e) {

        var hostengine = null;
        if( window && window.event && window.event.srcElement ) {
            hostengine = window.event.srcElement.tile_engine;
        } else if( e.target ) {
            hostengine = e.target.tile_engine;
        } else if( e.srcElement ) {
            hostengine = e.srcElement.tile_engine;
        }


        if( hostengine && hostengine.drag ) {
            if( hostengine.mousedown ) {
                if( netscape ) {
                    hostengine.mousex = parseInt(e.pageX) + 0.0;
                    hostengine.mousey = parseInt(e.pageY) + 0.0;
                } else {
                    hostengine.mousex = parseInt(window.event.clientX) + 0.0;
                    hostengine.mousey = parseInt(window.event.clientY) + 0.0;
                }
                hostengine.drag(hostengine.mousex-hostengine.lastmousex,hostengine.mousey-hostengine.lastmousey);
            }
            hostengine.lastmousex = hostengine.mousex;
            hostengine.lastmousey = hostengine.mousey;
        }

        // must return false to prevent operating system drag and drop from handling events
        return false;
    }

    ///
    /// catch mouse down
    ///

    this.event_mouse_down = function(e) {

        var hostengine = null;
        if( window && window.event && window.event.srcElement ) {
            hostengine = window.event.srcElement.tile_engine;
        } else if( e.target ) {
            hostengine = e.target.tile_engine;
        } else if( e.srcElement ) {
            hostengine = e.srcElement.tile_engine;
        }


        if( hostengine ) {
            if( netscape ) {
                hostengine.mousex = parseInt(e.pageX) + 0.0;
                hostengine.mousey = parseInt(e.pageY) + 0.0;
            } else {
                hostengine.mousex = parseInt(window.event.clientX) + 0.0;
                hostengine.mousey = parseInt(window.event.clientY) + 0.0;
            }
            hostengine.lastmousex = hostengine.mousex;
            hostengine.lastmousey = hostengine.mousey;
            hostengine.mousedown = 1;
        }

        // must return false to prevent operating system drag and drop from handling events
        return false;
    }

    ///
    /// catch double click (use to center map)
    ///

    this.event_double_click = function(e) {

        var hostengine = null;
        if( window && window.event && window.event.srcElement ) {
            hostengine = window.event.srcElement.tile_engine;
        } else if( e.target ) {
            hostengine = e.target.tile_engine;
        } else if( e.srcElement ) {
            hostengine = e.srcElement.tile_engine;
        }


        if( hostengine ) {
            if( netscape ) {
                hostengine.mousex = parseInt(e.pageX) + 0.0;
                hostengine.mousey = parseInt(e.pageY) + 0.0;
            } else {
                hostengine.mousex = parseInt(window.event.clientX) + 0.0;
                hostengine.mousey = parseInt(window.event.clientY) + 0.0;
            }
            var dx = hostengine.mousex-(hostengine.displaywidth/2)-hostengine.parent_x;
            var dy = hostengine.mousey-(hostengine.displayheight/2)-hostengine.parent_y;
            hostengine.drag(-dx,-dy); // TODO smooth
        }

        // must return false to prevent operating system drag and drop from handling events
        return false;

    }

    ///
    /// catch mouse up
    ///

    this.event_mouse_up = function(e) {

        var hostengine = null;
        if( window && window.event && window.event.srcElement ) {
            hostengine = window.event.srcElement.tile_engine;
        } else if( e.target ) {
            hostengine = e.target.tile_engine;
        } else if( e.srcElement ) {
            hostengine = e.srcElement.tile_engine;
        }
        

        if( hostengine ) {
            if( netscape ) {
                hostengine.mousex = parseInt(e.pageX) + 0.0;
                hostengine.mousey = parseInt(e.pageY) + 0.0;
            } else {
                hostengine.mousex = parseInt(window.event.clientX) + 0.0;
                hostengine.mousey = parseInt(window.event.clientY) + 0.0;
            }
            hostengine.mousedown = 0;
        }

        // must return false to prevent operating system drag and drop from handling events
        return false;
    }

    ///
    /// catch mouse out
    ///

    this.event_mouse_out = function(e) {

        var hostengine = null;
        if( window && window.event && window.event.srcElement ) {
            hostengine = window.event.srcElement.tile_engine;
        } else if( e.target ) {
            hostengine = e.target.tile_engine;
        } else if( e.srcElement ) {
            hostengine = e.srcElement.tile_engine;
        }


        if( hostengine ) {
            if( netscape ) {
                hostengine.mousex = parseInt(e.pageX) + 0.0;
                hostengine.mousey = parseInt(e.pageY) + 0.0;
            } else {
                hostengine.mousex = parseInt(window.event.clientX) + 0.0;
                hostengine.mousey = parseInt(window.event.clientY) + 0.0;
            }
            hostengine.mousedown = 0;
        }

        // must return false to prevent operating system drag and drop from handling events
        return false;
    }


    ///
    /// register new handlers to catch desired events
    ///

    // NW removed parameter - always use parent
    this.event_catch = function() {

    	this.parent.style.cursor = 'move';

        if( netscape ) {
            window.captureEvents(Event.MOUSEMOVE);
            window.captureEvents(Event.KEYPRESS);
        }

        this.parent.onmousemove = this.event_mouse_move;
        this.parent.onmousedown = this.event_mouse_down;
        this.parent.onmouseup = this.event_mouse_up;
        this.parent.onkeypress = this.event_key;
        window.ondblclick = this.event_double_click;

        if( window ) {
            window.onmousemove = this.event_mouse_move;
            window.onmouseup = this.event_mouse_up;
            window.ondblclick = this.event_double_click;
        }

    }

	this.setURLAttribute = function(k,v)
	{
		this.urlAttr[k] = v; 
	}

	this.getURLAttribute = function(k)
	{
		return this.urlAttr[k];
	}

	this.getDownloadedTileBounds = function()
	{
		var bounds = new Array();
		bounds.w=this.lon_min; 
		bounds.s=normallat(this.lat_min);
		bounds.e=this.lon_max;
		bounds.n=normallat(this.lat_max);
		return bounds;
	}

	this.getVisibleBounds = function()
	{
		var bounds = new Array();
		bounds.w = this.xToLon(0);
		bounds.s = this.yToLat(this.theheight);
		bounds.e = this.xToLon(this.thewidth);
		bounds.n = this.yToLat(0);
		return bounds;
	}
	
	// navout and navin stuff - START
	// draw navigation buttons into the parent div

    // ENTRY CODE BEGINS HERE....


    // get parent div or fail
    this.parent = document.getElementById(parentname);
    if( this.parent == null ) {
        alert('The tile map engine cannot find a parent container named ['
                +parentname+']');
        return;
    }

    //
    // store for later
    //

    this.parentname = parentname;
    this.hints = hints;
    this.feedurl = feedurl;
    this.url = url;
    this.lon = lon;
    this.lat = mercatorlat(lat);
    this.thewidth = w;
    this.theheight = h;
    this.dragcontainer = 1;
    this.debug = 0;

    // for firefox keyboard
    defaultEngine = this;
    document.engine = this;


    //
    // decide on display width and height
    //
    if( !w || !h ) 
	{
        w = parseInt(this.parent.style.width);
        h = parseInt(this.parent.style.height);
        if(!w || !h) 
		{
            w = 512;
            h = 256;
            this.parent.style.width = w + 'px';
            this.parent.style.height = h + 'px';
        }
    } 
	else 
	{
        this.parent.style.width = parseInt(w) + 'px';
        this.parent.style.height = parseInt(h) + 'px';
    }
    this.displaywidth = w;
    this.displayheight = h;

    this.minzoom = 0;
    this.maxzoom = 20;

    //
    // enforce parent div style?
    // position absolute is really only required for firefox
    // http://www.quirksmode.org/js/findpos.html
    //

    this.parent_x = getCSSPositionX(this.parent);
    this.parent_y = getCSSPositionY(this.parent);

    this.parent.style.position = 'relative';
    this.parent.style.overflow = 'hidden';
    this.parent.style.backgroundColor = '#000036';


	// attach event capture parent div
	this.event_catch();

    this.clean();
	//this.makeZoom();

    this.zoomTo(zoom);
}


function normallat(mercatorlat)
{
    var tp = 180/PI*(2 * Math.atan(Math.exp(mercatorlat * PI / 180)) - PI / 2);
    return tp;
}

function mercatorlat(normallat)
{
  var lpi =  3.14159265358979323846;
  return  Math.log( Math.tan( (lpi / 4.0) + (normallat / 180.0 * lpi / 2.0))) * 
                      180.0 / lpi ;
}
