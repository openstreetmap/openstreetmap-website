L.extend(L.LatLngBounds.prototype, {
  getSize: function () {
    return (this._northEast.lat - this._southWest.lat) *
           (this._northEast.lng - this._southWest.lng);
  },

  wrap: function () {
    return new L.LatLngBounds(this._southWest.wrap(), this._northEast.wrap());
  }
});

L.OSM.Map = L.Map.extend({
  initialize: function(id, options) {
    L.Map.prototype.initialize.call(this, id, options);

    var copyright = I18n.t('javascripts.map.copyright', {copyright_url: '/copyright'});
    var donate = I18n.t('javascripts.map.donate_link_text', {donate_url: 'http://donate.openstreetmap.org'});

    this.baseLayers = [
      new L.OSM.Mapnik({
        attribution: copyright + " &hearts; " + donate,
        code: "M",
        keyid: "mapnik",
        name: I18n.t("javascripts.map.base.standard")
      }),
      new L.OSM.CycleMap({
        attribution: copyright + ". Tiles courtesy of <a href='http://www.thunderforest.com/' target='_blank'>Andy Allan</a>",
        code: "C",
        keyid: "cyclemap",
        name: I18n.t("javascripts.map.base.cycle_map")
      }),
      new L.OSM.TransportMap({
        attribution: copyright + ". Tiles courtesy of <a href='http://www.thunderforest.com/' target='_blank'>Andy Allan</a>",
        code: "T",
        keyid: "transportmap",
        name: I18n.t("javascripts.map.base.transport_map")
      }),
      new L.OSM.MapQuestOpen({
        attribution: copyright + ". Tiles courtesy of <a href='http://www.mapquest.com/' target='_blank'>MapQuest</a> <img src='https://developer.mapquest.com/content/osm/mq_logo.png'>",
        code: "Q",
        keyid: "mapquest",
        name: I18n.t("javascripts.map.base.mapquest")
      }),
      new L.OSM.HOT({
        attribution: copyright + ". Tiles courtesy of <a href='http://hot.openstreetmap.org/' target='_blank'>Humanitarian OpenStreetMap Team</a>",
        code: "H",
        keyid: "hot",
        name: I18n.t("javascripts.map.base.hot")
      })
    ];

    this.noteLayer = new L.FeatureGroup();
    this.noteLayer.options = {code: 'N'};

    this.dataLayer = new L.OSM.DataLayer(null);
    this.dataLayer.options.code = 'D';
  },

  updateLayers: function(layerParam) {
    layerParam = layerParam || "M";
    var layersAdded = "";

    for (var i = this.baseLayers.length - 1; i >= 0; i--) {
      if (layerParam.indexOf(this.baseLayers[i].options.code) >= 0) {
        this.addLayer(this.baseLayers[i]);
        layersAdded = layersAdded + this.baseLayers[i].options.code;
      } else if (i === 0 && layersAdded === "") {
        this.addLayer(this.baseLayers[i]);
      } else {
        this.removeLayer(this.baseLayers[i]);
      }
    }
  },

  getLayersCode: function () {
    var layerConfig = '';
    for (var i in this._layers) { // TODO: map.eachLayer
      var layer = this._layers[i];
      if (layer.options && layer.options.code) {
        layerConfig += layer.options.code;
      }
    }
    return layerConfig;
  },

  getMapBaseLayerId: function () {
    for (var i in this._layers) { // TODO: map.eachLayer
      var layer = this._layers[i];
      if (layer.options && layer.options.keyid) return layer.options.keyid;
    }
  },

  getUrl: function(marker) {
    var precision = OSM.zoomPrecision(this.getZoom()),
        params = {};

    if (marker && this.hasLayer(marker)) {
      var latLng = marker.getLatLng().wrap();
      params.mlat = latLng.lat.toFixed(precision);
      params.mlon = latLng.lng.toFixed(precision);
    }

    var url = 'http://' + OSM.SERVER_URL + '/',
      query = querystring.stringify(params),
      hash = OSM.formatHash(this);

    if (query) url += '?' + query;
    if (hash) url += hash;

    return url;
  },

  getShortUrl: function(marker) {
    var zoom = this.getZoom(),
      latLng = marker && this.hasLayer(marker) ? marker.getLatLng().wrap() : this.getCenter().wrap(),
      str = window.location.hostname.match(/^www\.openstreetmap\.org/i) ?
        'http://osm.org/go/' : 'http://' + window.location.hostname + '/go/',
      char_array = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_~",
      x = Math.round((latLng.lng + 180.0) * ((1 << 30) / 90.0)),
      y = Math.round((latLng.lat + 90.0) * ((1 << 30) / 45.0)),
      // JavaScript only has to keep 32 bits of bitwise operators, so this has to be
      // done in two parts. each of the parts c1/c2 has 30 bits of the total in it
      // and drops the last 4 bits of the full 64 bit Morton code.
      c1 = interlace(x >>> 17, y >>> 17), c2 = interlace((x >>> 2) & 0x7fff, (y >>> 2) & 0x7fff),
      digit;

    for (var i = 0; i < Math.ceil((zoom + 8) / 3.0) && i < 5; ++i) {
      digit = (c1 >> (24 - 6 * i)) & 0x3f;
      str += char_array.charAt(digit);
    }
    for (i = 5; i < Math.ceil((zoom + 8) / 3.0); ++i) {
      digit = (c2 >> (24 - 6 * (i - 5))) & 0x3f;
      str += char_array.charAt(digit);
    }
    for (i = 0; i < ((zoom + 8) % 3); ++i) str += "-";

    // Called to interlace the bits in x and y, making a Morton code.
    function interlace(x, y) {
      x = (x | (x << 8)) & 0x00ff00ff;
      x = (x | (x << 4)) & 0x0f0f0f0f;
      x = (x | (x << 2)) & 0x33333333;
      x = (x | (x << 1)) & 0x55555555;
      y = (y | (y << 8)) & 0x00ff00ff;
      y = (y | (y << 4)) & 0x0f0f0f0f;
      y = (y | (y << 2)) & 0x33333333;
      y = (y | (y << 1)) & 0x55555555;
      return (x << 1) | y;
    }

    var params = {};
    var layers = this.getLayersCode().replace('M', '');

    if (layers) {
      params.layers = layers;
    }

    if (marker && this.hasLayer(marker)) {
      params.m = '';
    }

    if (this._object) {
      params[this._object.type] = this._object.id;
    }

    var query = querystring.stringify(params);
    if (query) {
      str += '?' + query;
    }

    return str;
  },

  addObject: function(object, callback) {
    var objectStyle = {
      color: "#FF6200",
      weight: 4,
      opacity: 1,
      fillOpacity: 0.5
    };

    var changesetStyle = {
      weight: 4,
      color: '#FF9500',
      opacity: 1,
      fillOpacity: 0,
      clickable: false
    };

    this._object = object;

    if (this._objectLoader) this._objectLoader.abort();
    if (this._objectLayer) this.removeLayer(this._objectLayer);

    var map = this;
    this._objectLoader = $.ajax({
      url: OSM.apiUrl(object),
      dataType: "xml",
      success: function (xml) {
        map._objectLayer = new L.OSM.DataLayer(null, {
          styles: {
            node: objectStyle,
            way: objectStyle,
            area: objectStyle,
            changeset: changesetStyle
          }
        });

        map._objectLayer.interestingNode = function (node, ways, relations) {
          if (object.type === "node") {
            return true;
          } else if (object.type === "relation") {
            for (var i = 0; i < relations.length; i++)
              if (relations[i].members.indexOf(node) !== -1)
                return true;
          } else {
            return false;
          }
        };

        map._objectLayer.addData(xml);
        map._objectLayer.addTo(map);

        if (callback) callback(map._objectLayer.getBounds());
      }
    });
  },

  removeObject: function() {
    this._object = null;
    if (this._objectLoader) this._objectLoader.abort();
    if (this._objectLayer) this.removeLayer(this._objectLayer);
  },

  getState: function() {
    return {
      center: this.getCenter().wrap(),
      zoom: this.getZoom(),
      layers: this.getLayersCode()
    };
  },

  setState: function(state, options) {
    if (state.center) this.setView(state.center, state.zoom, options);
    if (state.layers) this.updateLayers(state.layers);
  },

  setSidebarOverlaid: function(overlaid) {
    if (overlaid && !$("#content").hasClass("overlay-sidebar")) {
      $("#content").addClass("overlay-sidebar");
      this.invalidateSize({pan: false})
        .panBy([-350, 0], {animate: false});
    } else if (!overlaid && $("#content").hasClass("overlay-sidebar")) {
      this.panBy([350, 0], {animate: false});
      $("#content").removeClass("overlay-sidebar");
      this.invalidateSize({pan: false});
    }
    return this;
  }
});

L.Icon.Default.imagePath = "/images";

L.Icon.Default.imageUrls = {
  "/images/marker-icon.png": OSM.MARKER_ICON,
  "/images/marker-icon-2x.png": OSM.MARKER_ICON_2X,
  "/images/marker-shadow.png": OSM.MARKER_SHADOW
};

L.extend(L.Icon.Default.prototype, {
  _oldGetIconUrl: L.Icon.Default.prototype._getIconUrl,

  _getIconUrl:  function (name) {
    var url = this._oldGetIconUrl(name);
    return L.Icon.Default.imageUrls[url];
  }
});

function getUserIcon(url) {
  return L.icon({
    iconUrl: url || OSM.MARKER_RED,
    iconSize: [25, 41],
    iconAnchor: [12, 41],
    popupAnchor: [1, -34],
    shadowUrl: OSM.MARKER_SHADOW,
    shadowSize: [41, 41]
  });
}
