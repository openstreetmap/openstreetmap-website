/*
 * L.PolylineUtil contains utilify functions for polylines, two methods
 * are added to the L.Polyline object to support creation of polylines
 * from an encoded string and converting existing polylines to an
 * encoded string.
 *
 *  - L.Polyline.fromEncoded(encoded [, options]) returns a L.Polyline
 *  - L.Polyline.encodePath() returns a string
 *
 * Actual code from:
 * http://facstaff.unca.edu/mcmcclur/GoogleMaps/EncodePolyline/\
 */

/*jshint browser:true, debug: true, strict:false, globalstrict:false, indent:4, white:true, smarttabs:true*/
/*global L:true, console:true*/


// Inject functionality into Leaflet
(function (L) {
	if (!(L.Polyline.prototype.fromEncoded)) {
		L.Polyline.fromEncoded = function (encoded, options) {
			return new L.Polyline(L.PolylineUtil.decode(encoded), options);
		};
	}
	if (!(L.Polygon.prototype.fromEncoded)) {
		L.Polygon.fromEncoded = function (encoded, options) {
			return new L.Polygon(L.PolylineUtil.decode(encoded), options);
		};
	}

	var encodeMixin = {
		encodePath: function () {
			return L.PolylineUtil.encode(this.getLatLngs());
		}
	};

	if (!L.Polyline.prototype.encodePath) {
		L.Polyline.include(encodeMixin);
	}
	if (!L.Polygon.prototype.encodePath) {
		L.Polygon.include(encodeMixin);
	}
})(L);

// Utility functions.
L.PolylineUtil = {};

L.PolylineUtil.encode = function (latlngs) {
	var i, dlat, dlng;
	var plat = 0;
	var plng = 0;
	var encoded_points = "";

	for (i = 0; i < latlngs.length; i++) {
		var lat = latlngs[i].lat;
		var lng = latlngs[i].lng;
		var late5 = Math.floor(lat * 1e5);
		var lnge5 = Math.floor(lng * 1e5);
		dlat = late5 - plat;
		dlng = lnge5 - plng;
		plat = late5;
		plng = lnge5;
		encoded_points +=
			L.PolylineUtil.encodeSignedNumber(dlat) +
			L.PolylineUtil.encodeSignedNumber(dlng);
	}
	return encoded_points;
};

// This function is very similar to Google's, but I added
// some stuff to deal with the double slash issue.
L.PolylineUtil.encodeNumber = function (num) {
	var encodeString = "";
	var nextValue, finalValue;
	while (num >= 0x20) {
		nextValue = (0x20 | (num & 0x1f)) + 63;
		encodeString += (String.fromCharCode(nextValue));
		num >>= 5;
	}
	finalValue = num + 63;
	encodeString += (String.fromCharCode(finalValue));
	return encodeString;
};

// This one is Google's verbatim.
L.PolylineUtil.encodeSignedNumber = function (num) {
	var sgn_num = num << 1;
	if (num < 0) {
		sgn_num = ~(sgn_num);
	}
	return (L.PolylineUtil.encodeNumber(sgn_num));
};

L.PolylineUtil.decode = function (encoded) {
	var len = encoded.length;
	var index = 0;
	var latlngs = [];
	var lat = 0;
	var lng = 0;

	while (index < len) {
		var b;
		var shift = 0;
		var result = 0;
		do {
			b = encoded.charCodeAt(index++) - 63;
			result |= (b & 0x1f) << shift;
			shift += 5;
		} while (b >= 0x20);
		var dlat = ((result & 1) ? ~(result >> 1) : (result >> 1));
		lat += dlat;

		shift = 0;
		result = 0;
		do {
			b = encoded.charCodeAt(index++) - 63;
			result |= (b & 0x1f) << shift;
			shift += 5;
		} while (b >= 0x20);
		var dlng = ((result & 1) ? ~(result >> 1) : (result >> 1));
		lng += dlng;

		latlngs.push(new L.LatLng(lat * 1e-5, lng * 1e-5));
	}

	return latlngs;
};