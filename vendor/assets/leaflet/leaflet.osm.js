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
    maxZoom: 19,
    referrerPolicy: 'strict-origin-when-cross-origin'
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

L.OSM.TransportDarkMap = L.OSM.TileLayer.extend({
  options: {
    url: 'https://{s}.tile.thunderforest.com/transport-dark/{z}/{x}/{y}{r}.png?apikey={apikey}',
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

L.OSM.HOT = L.OSM.TileLayer.extend({
  options: {
    url: 'https://tile-{s}.openstreetmap.fr/hot/{z}/{x}/{y}.png',
    maxZoom: 20,
    subdomains: 'abc',
    attribution: '© <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap</a> contributors. Tiles courtesy of <a href="http://hot.openstreetmap.org/" target="_blank">Humanitarian OpenStreetMap Team</a>'
  }
});

L.OSM.TracestrackTopo = L.OSM.TileLayer.extend({
  options: {
    url: 'https://tile.tracestrack.com/topo__/{z}/{x}/{y}.webp?key={apikey}',
    maxZoom: 19,
    attribution: '© <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap</a> contributors. Tiles courtesy of <a href="https://www.tracestrack.com/" target="_blank">Tracestrack Maps</a>'
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
    styles: {},
    asynchronous: false,
  },

  initialize: function (xml, options) {
    L.Util.setOptions(this, options);

    L.FeatureGroup.prototype.initialize.call(this);

    if (xml) {
      this.addData(xml);
    }
  },

  loadingLayers: [],

  cancelLoading: function () {
    this.loadingLayers.forEach(layer => clearTimeout(layer));
    this.loadingLayers = [];
  },

  addData: function (features) {
    if (!(features instanceof Array)) {
      features = this.buildFeatures(features);
    }

    for (var i = 0; i < features.length; i++) {
      let feature = features[i], layer;

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

      if (this.options.asynchronous) {
        setTimeout(() => layer.addTo(this));
      } else {
        layer.addTo(this);
      }

      layer.feature = feature;
    }
  },

  buildFeatures: function (data) {

    const parser = data instanceof Document ? L.OSM.XMLParser : L.OSM.JSONParser;

    var features = parser.getChangesets(data),
        nodes = parser.getNodes(data),
        ways = parser.getWays(data, nodes),
        relations = parser.getRelations(data, nodes, ways);

    var wayNodes = {}
    for (var i = 0; i < ways.length; i++) {
      var way = ways[i];
      for (var j = 0; j < way.nodes.length; j++) {
        wayNodes[way.nodes[j].id] = true
      }
    }

    var relationNodes = {}
    for (var i = 0; i < relations.length; i++){
      var relation = relations[i];
      for (var j = 0; j < relation.members.length; j++) {
        relationNodes[relation.members[j].id] = true
      }
    }

    for (var node_id in nodes) {
      var node = nodes[node_id];
      if (this.interestingNode(node, wayNodes, relationNodes)) {
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

  interestingNode: function (node, wayNodes, relationNodes) {
    if (!wayNodes[node.id] || relationNodes[node.id]) {
      return true
    }

    for (var key in node.tags) {
      if (this.options.uninterestingTags.indexOf(key) < 0) {
        return true;
      }
    }

    return false;
  },

  onRemove: function(map) {
    this.eachLayer(map.removeLayer, map, this.options.asynchronous);
  },

  onAdd: function(map) {
    this.eachLayer(map.addLayer, map, this.options.asynchronous);
  },

  eachLayer: function (method, context, asynchronous = false) {
    for (let i in this._layers) {
      if (asynchronous) {
        this.loadingLayers.push(
          setTimeout(() => {
            method.call(context, this._layers[i]);
          })
        );
      } else {
        method.call(context, this._layers[i]);
      }
    }
    return this;
  },
});

L.OSM.XMLParser = {
  getChangesets(xml) {
    const changesets = [...xml.getElementsByTagName("changeset")];
    return changesets.map(cs => ({
      id: String(cs.getAttribute("id")),
      type: "changeset",
      latLngBounds: L.latLngBounds(
        [cs.getAttribute("min_lat"), cs.getAttribute("min_lon")],
        [cs.getAttribute("max_lat"), cs.getAttribute("max_lon")]
      ),
      tags: this.getTags(cs)
    }));
  },

  getNodes(xml) {
    const result = {};
    const nodes = [...xml.getElementsByTagName("node")];

    for (const node of nodes) {
      const id = node.getAttribute("id");
      result[id] = {
        id: String(id),
        type: "node",
        latLng: L.latLng(
          node.getAttribute("lat"),
          node.getAttribute("lon"),
          true
        ),
        tags: this.getTags(node)
      };
    }

    return result;
  },

  getWays(xml, nodes) {
    const ways = [...xml.getElementsByTagName("way")];
    return ways.map(way => {
      const nds = [...way.getElementsByTagName("nd")];
      return {
        id: String(way.getAttribute("id")),
        type: "way",
        nodes: nds.map(nd => nodes[nd.getAttribute("ref")]),
        tags: this.getTags(way)
      };
    });
  },

  getRelations(xml, nodes, ways) {
    const rels = [...xml.getElementsByTagName("relation")];
    return rels.map(rel => {
      const members = [...rel.getElementsByTagName("member")];
      return {
        id: String(rel.getAttribute("id")),
        type: "relation",
        members: members    // relation-way and relation-relation membership not implemented
          .map(member => member.getAttribute("type") === "node" ? nodes[member.getAttribute("ref")] : null)
          .filter(Boolean),    // filter out null and undefined
        tags: this.getTags(rel)
      };
    });
  },

  getTags(xml) {
    const result = {};
    const tags = [...xml.getElementsByTagName("tag")];

    for (const tag of tags) {
      result[tag.getAttribute("k")] = tag.getAttribute("v");
    }

    return result;
  }
}

L.OSM.JSONParser = {
  getChangesets(json) {
    const changesets = json.changeset ? [json.changeset] : [];

    return changesets.map(cs => ({
      id: String(cs.id),
      type: "changeset",
      latLngBounds: L.latLngBounds(
        [cs.min_lat, cs.min_lon],
        [cs.max_lat, cs.max_lon]
      ),
      tags: this.getTags(cs)
    }));
  },

  getNodes(json) {
    const nodes = json.elements?.filter(el => el.type === "node") ?? [];
    let result = {};

    for (const node of nodes) {
      result[node.id] = {
        id: String(node.id),
        type: "node",
        latLng: L.latLng(node.lat, node.lon, true),
        tags: this.getTags(node)
      };
    }

    return result;
  },

  getWays(json, nodes) {
    const ways = json.elements?.filter(el => el.type === "way") ?? [];

    return ways.map(way => ({
      id: String(way.id),
      type: "way",
      nodes: way.nodes.map(nodeId => nodes[nodeId]),
      tags: this.getTags(way)
    }));
  },

  getRelations(json, nodes, ways) {
    const relations = json.elements?.filter(el => el.type === "relation") ?? [];

    return relations.map(rel => ({
      id: String(rel.id),
      type: "relation",
      members: (rel.members ?? [])   // relation-way and relation-relation membership not implemented
        .map(member => member.type === "node" ? nodes[member.ref] : null)
        .filter(Boolean),     // filter out null and undefined
      tags: this.getTags(rel)
    }));
  },

  getTags(json) {
    return json.tags ?? {};
  }
};
