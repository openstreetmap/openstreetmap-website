/*
    Copyright (C) 2004-05 Nick Whitelegg, Hogweed Software, nick@hogweed.org 

    This program is free software; you can redistribute it and/or modify
    it under the terms of the Lesser GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    Lesser GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111 USA

*/

// These are functions which manipulate the slippy map in various ways
// The idea has been to try and clean up the slippy map API and take code
// which does not manipulate it directly outside.

var view=0, tileURL, tile_engine; 

function init()
{
	tileURL = 'http://tile.openstreetmap.org/ruby/wmsmod.rbx';
	tile_engine = new tile_engine_new('drag','FULL','',tileURL,lon,lat,zoom,700,500);

	tile_engine.setURLAttribute("landsat",1);

	document.getElementById('zoomout').onclick = zoomOut;
	document.getElementById('zoomin').onclick = zoomIn;
	/*
	document.getElementById('landsat').onclick = landsatToggle;
	*/

	//document.getElementById('posGo').onclick = setPosition;
}

function zoomIn()
{
	tile_engine.tile_engine_zoomin();
}

function zoomOut()
{
	tile_engine.tile_engine_zoomout();
}

function enableTileEngine()
{
	tile_engine.event_catch();
}

function landsatToggle()
{
	var lsat = tile_engine.getURLAttribute("landsat");
	tile_engine.setURLAttribute("landsat", (lsat) ? 0: 1);
	tile_engine.forceRefresh();
}

function setPosition()
{
	/*
	var txtLat = document.getElementById("txtLat"),
		txtLon = document.getElementById("txtLon");

	tile_engine.setLatLon(txtLat, txtLon);
	*/
}
