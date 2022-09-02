//= require maplibre-gl
//= require @maplibre/maplibre-gl-leaflet
//= require i18n

L.OSM = {};

L.OSM.TileLayer = L.TileLayer.extend({
  options: {
    url: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: '© <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap</a> contributors'
  },

  initialize: function (options) {
    options = L.Util.setOptions(this, options);
    L.TileLayer.prototype.initialize.call(this, options.url);
  }
});

L.OSM.Mapnik = L.OSM.TileLayer.extend({
  options: {
    url: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    maxZoom: 19
  }
});

L.OSM.CyclOSM = L.OSM.TileLayer.extend({
  options: {
    url: 'https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png',
    maxZoom: 20,
    subdomains: 'abc',
    attribution: '© <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap</a> contributors. Tiles courtesy of <a href="https://www.openstreetmap.fr" target="_blank">OpenStreetMap France</a>'
  }
});

L.OSM.CycleMap = L.OSM.TileLayer.extend({
  options: {
    url: 'https://{s}.tile.thunderforest.com/cycle/{z}/{x}/{y}{r}.png?apikey={apikey}',
    maxZoom: 21,
    attribution: '© <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap</a> contributors. Tiles courtesy of <a href="http://www.thunderforest.com/" target="_blank">Andy Allan</a>'
  }
});

L.OSM.TransportMap = L.OSM.TileLayer.extend({
  options: {
    url: 'https://{s}.tile.thunderforest.com/transport/{z}/{x}/{y}{r}.png?apikey={apikey}',
    maxZoom: 21,
    attribution: '© <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap</a> contributors. Tiles courtesy of <a href="http://www.thunderforest.com/" target="_blank">Andy Allan</a>'
  }
});

L.OSM.OPNVKarte = L.OSM.TileLayer.extend({
  options: {
    url: 'https://tileserver.memomaps.de/tilegen/{z}/{x}/{y}.png',
    maxZoom: 18,
    attribution: '© <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap</a> contributors. Tiles courtesy of <a href="http://memomaps.de/" target="_blank">MeMoMaps</a>'
  }
});

L.OSM.OpenMapTiles = L.MaplibreGL.extend({
  isTokenField: /^\{name/,
  _isLanguageField: /^name:/,
  options: {
    style: 'https://api.maptiler.com/maps/openstreetmap/style.json?key=lmYA16sOOOz9r6DH7iA9',
    maxZoom: 23,
    attribution: '© <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap</a> contributors. Tiles courtesy of <a href="http://memomaps.de/" target="_blank">MeMoMaps</a>'
  },
  adaptPropertyLanguageWithLegacySupport(
    isLangField,
    property,
    languageFieldName,
  ) {
    if (
      property.length === 4 &&
      property[0] === 'coalesce' &&
      typeof property[3] === 'string' &&
      this.isTokenField.test(property[3])
    ) {
      // Back to original format string for legacy
      property = property[3];
    }

    if (typeof property === 'string') {
      // Only support legacy format string at top level
      if (languageFieldName !== 'name' && this.isTokenField.test(property)) {
        var splitLegacity = this.splitLegacityFormat(property);
        // The last is not used, it is the original value to be restore
        return [
          'coalesce',
          this.adaptLegacyExpression(splitLegacity, languageFieldName),
          splitLegacity,
          property,
        ];
      } else {
        return property;
      }
    } else {
      return this.adaptPropertyLanguage(isLangField, property, languageFieldName);
    }
  },
  splitLegacityFormat(s) {
    var ret = ['concat'];
    var sub = '';
    for (var i = 0; i < s.length; i++) {
      if (s[i] === '{') {
        if (sub) {
          ret.push(sub);
        }
        sub = '';
      } else if (s[i] === '}') {
        if (sub) {
          ret.push(['get', sub]);
        }
        sub = '';
      } else {
        sub += s[i];
      }
    }

    if (sub) {
      ret.push(sub);
    }

    return ret;
  },
  adaptLegacyExpression(expressions, languageFieldName) {
    // Kepp only first get name express
    var isName = false;
    var ret = [];
    var self = this;
    expressions.forEach(function (expression) {
      // ['get', 'name:.*']
      if (
        Array.isArray(expression) &&
        expression.length >= 2 &&
        typeof expression[1] === 'string' &&
        self._isLanguageField.test(expression[1])
      ) {
        if (!isName) {
          isName = true;
          ret.push(['coalesce', ['get', languageFieldName], expression]);
        }
      } else {
        ret.push(expression);
      }
    });

    return ret;
  },
  adaptNestedExpressionField(
    isLangField,
    properties,
    languageFieldName,
  ) {
    var self = this;
    properties.forEach(function (property) {
      if (Array.isArray(property)) {
        if (self.isFlatExpressionField(isLangField, property)) {
          property[1] = languageFieldName;
        }
        self.adaptNestedExpressionField(isLangField, property, languageFieldName);
      }
    });
  },
  adaptPropertyLanguage(
    isLangField,
    property,
    languageFieldName,
  ) {
    if (this.isFlatExpressionField(isLangField, property)) {
      property[1] = languageFieldName;
    }

    this.adaptNestedExpressionField(isLangField, property, languageFieldName);

    // handle special case of bare ['get', 'name'] expression by wrapping it in a coalesce statement
    if (property[0] === 'get' && property[1] === 'name') {
      var defaultProp = property.slice();
      var adaptedProp = ['get', languageFieldName];
      property = ['coalesce', adaptedProp, defaultProp];
    }

    return property;
  },
  isFlatExpressionField(isLangField, property) {
    var isGetExpression = property.length >= 2 && property[0] === 'get';
    if (isGetExpression && typeof property[1] === 'string' && this.isTokenField.test(property[1])) {
      console.warn(
        'This plugin no longer supports the use of token syntax (e.g. {name}). Please use a get expression. See https://docs.mapbox.com/mapbox-gl-js/style-spec/expressions/ for more details.',
      );
    }

    return isGetExpression && typeof property[1] === 'string' && isLangField.test(property[1]);
  },
  _getLanguageField(language) {
    return language === 'mul' ? 'name' : `name:${language}`;
  },
  onAdd(map) {
    L.MaplibreGL.prototype.onAdd.call(this, map);

    var lang = I18n.locale; // TODO filter only supported locales

    var m = this.getMaplibreMap();

    var self = this;

    m.on('load', function () {
      m.getStyle().layers.filter(function (layer) { return layer.type === 'symbol'}).forEach(function (layer) {
        if (layer.layout && typeof layer.layout['text-field'] === 'string') {
          m.setLayoutProperty(
            layer.id,
            'text-field',
            self.adaptPropertyLanguageWithLegacySupport(
              /^name:/,
              layer.layout['text-field'],
              self._getLanguageField(lang),
            ),
          );
        }

        // if (/^country_/.test(layer.id)) {
        //   var dflt = ["get", "name:latin"];

        //   m.setLayoutProperty(
        //     layer.id,
        //     "text-field",
        //     lang ? ["coalesce", ["get", "name:" + lang], dflt] : dflt
        //   );
        // }

        // if (/^place_/.test(layer.id)) {
        //   var dflt = [
        //     "concat",
        //     ["get", "name:latin"],
        //     "\n",
        //     ["get", "name:nonlatin"],
        //   ];

        //   m.setLayoutProperty(
        //     layer.id,
        //     "text-field",
        //     lang ? ["coalesce", ["get", "name:" + lang], dflt] : dflt
        //   );
        // }
      });
    });
  }
});

L.OSM.HOT = L.OSM.TileLayer.extend({
  options: {
    url: 'https://tile-{s}.openstreetmap.fr/hot/{z}/{x}/{y}.png',
    maxZoom: 20,
    subdomains: 'abc',
    attribution: '© <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap</a> contributors. Tiles courtesy of <a href="http://hot.openstreetmap.org/" target="_blank">Humanitarian OpenStreetMap Team</a>'
  }
});

L.OSM.GPS = L.OSM.TileLayer.extend({
  options: {
    url: 'https://gps.tile.openstreetmap.org/lines/{z}/{x}/{y}.png',
    maxZoom: 21,
    maxNativeZoom: 20,
    subdomains: 'abc'
  }
});

L.OSM.DataLayer = L.FeatureGroup.extend({
  options: {
    areaTags: ['area', 'building', 'leisure', 'tourism', 'ruins', 'historic', 'landuse', 'military', 'natural', 'sport'],
    uninterestingTags: ['source', 'source_ref', 'source:ref', 'history', 'attribution', 'created_by', 'tiger:county', 'tiger:tlid', 'tiger:upload_uuid'],
    styles: {}
  },

  initialize: function (xml, options) {
    L.Util.setOptions(this, options);

    L.FeatureGroup.prototype.initialize.call(this);

    if (xml) {
      this.addData(xml);
    }
  },

  addData: function (features) {
    if (!(features instanceof Array)) {
      features = this.buildFeatures(features);
    }

    for (var i = 0; i < features.length; i++) {
      var feature = features[i], layer;

      if (feature.type === "changeset") {
        layer = L.rectangle(feature.latLngBounds, this.options.styles.changeset);
      } else if (feature.type === "node") {
        layer = L.circleMarker(feature.latLng, this.options.styles.node);
      } else {
        var latLngs = new Array(feature.nodes.length);

        for (var j = 0; j < feature.nodes.length; j++) {
          latLngs[j] = feature.nodes[j].latLng;
        }

        if (this.isWayArea(feature)) {
          latLngs.pop(); // Remove last == first.
          layer = L.polygon(latLngs, this.options.styles.area);
        } else {
          layer = L.polyline(latLngs, this.options.styles.way);
        }
      }

      layer.addTo(this);
      layer.feature = feature;
    }
  },

  buildFeatures: function (xml) {
    var features = L.OSM.getChangesets(xml),
      nodes = L.OSM.getNodes(xml),
      ways = L.OSM.getWays(xml, nodes),
      relations = L.OSM.getRelations(xml, nodes, ways);

    for (var node_id in nodes) {
      var node = nodes[node_id];
      if (this.interestingNode(node, ways, relations)) {
        features.push(node);
      }
    }

    for (var i = 0; i < ways.length; i++) {
      var way = ways[i];
      features.push(way);
    }

    return features;
  },

  isWayArea: function (way) {
    if (way.nodes[0] != way.nodes[way.nodes.length - 1]) {
      return false;
    }

    for (var key in way.tags) {
      if (~this.options.areaTags.indexOf(key)) {
        return true;
      }
    }

    return false;
  },

  interestingNode: function (node, ways, relations) {
    var used = false;

    for (var i = 0; i < ways.length; i++) {
      if (ways[i].nodes.indexOf(node) >= 0) {
        used = true;
        break;
      }
    }

    if (!used) {
      return true;
    }

    for (var i = 0; i < relations.length; i++) {
      if (relations[i].members.indexOf(node) >= 0)
        return true;
    }

    for (var key in node.tags) {
      if (this.options.uninterestingTags.indexOf(key) < 0) {
        return true;
      }
    }

    return false;
  }
});

L.Util.extend(L.OSM, {
  getChangesets: function (xml) {
    var result = [];

    var nodes = xml.getElementsByTagName("changeset");
    for (var i = 0; i < nodes.length; i++) {
      var node = nodes[i], id = node.getAttribute("id");
      result.push({
        id: id,
        type: "changeset",
        latLngBounds: L.latLngBounds(
          [node.getAttribute("min_lat"), node.getAttribute("min_lon")],
          [node.getAttribute("max_lat"), node.getAttribute("max_lon")]),
        tags: this.getTags(node)
      });
    }

    return result;
  },

  getNodes: function (xml) {
    var result = {};

    var nodes = xml.getElementsByTagName("node");
    for (var i = 0; i < nodes.length; i++) {
      var node = nodes[i], id = node.getAttribute("id");
      result[id] = {
        id: id,
        type: "node",
        latLng: L.latLng(node.getAttribute("lat"),
                         node.getAttribute("lon"),
                         true),
        tags: this.getTags(node)
      };
    }

    return result;
  },

  getWays: function (xml, nodes) {
    var result = [];

    var ways = xml.getElementsByTagName("way");
    for (var i = 0; i < ways.length; i++) {
      var way = ways[i], nds = way.getElementsByTagName("nd");

      var way_object = {
        id: way.getAttribute("id"),
        type: "way",
        nodes: new Array(nds.length),
        tags: this.getTags(way)
      };

      for (var j = 0; j < nds.length; j++) {
        way_object.nodes[j] = nodes[nds[j].getAttribute("ref")];
      }

      result.push(way_object);
    }

    return result;
  },

  getRelations: function (xml, nodes, ways) {
    var result = [];

    var rels = xml.getElementsByTagName("relation");
    for (var i = 0; i < rels.length; i++) {
      var rel = rels[i], members = rel.getElementsByTagName("member");

      var rel_object = {
        id: rel.getAttribute("id"),
        type: "relation",
        members: new Array(members.length),
        tags: this.getTags(rel)
      };

      for (var j = 0; j < members.length; j++) {
        if (members[j].getAttribute("type") === "node")
          rel_object.members[j] = nodes[members[j].getAttribute("ref")];
        else // relation-way and relation-relation membership not implemented
          rel_object.members[j] = null;
      }

      result.push(rel_object);
    }

    return result;
  },

  getTags: function (xml) {
    var result = {};

    var tags = xml.getElementsByTagName("tag");
    for (var j = 0; j < tags.length; j++) {
      result[tags[j].getAttribute("k")] = tags[j].getAttribute("v");
    }

    return result;
  }
});
