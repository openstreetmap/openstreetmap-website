L.OSM = {};

L.OSM.TileLayer = L.TileLayer.extend({
  options: {
    url: 'http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: '© <a target="_parent" href="http://www.openstreetmap.org">OpenStreetMap</a> and contributors, under an <a target="_parent" href="http://www.openstreetmap.org/copyright">open license</a>'
  },

  initialize: function (options) {
    options = L.Util.setOptions(this, options);
    L.TileLayer.prototype.initialize.call(this, options.url);
  }
});

L.OSM.Mapnik = L.OSM.TileLayer.extend({
  options: {
    url: 'http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'
  }
});

L.OSM.CycleMap = L.OSM.TileLayer.extend({
  options: {
    url: 'http://{s}.tile.opencyclemap.org/cycle/{z}/{x}/{y}.png'
  }
});

L.OSM.TransportMap = L.OSM.TileLayer.extend({
  options: {
    url: 'http://{s}.tile2.opencyclemap.org/transport/{z}/{x}/{y}.png'
  }
});

L.OSM.MapQuestOpen = L.OSM.TileLayer.extend({
  options: {
    url: 'http://otile{s}.mqcdn.com/tiles/1.0.0/osm/{z}/{x}/{y}.png',
    subdomains: '1234',
    attribution: "Tiles courtesy of <a href='http://www.mapquest.com/' target='_blank'>MapQuest</a> <img src='http://developer.mapquest.com/content/osm/mq_logo.png'>"
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

  addData: function (xml) {
    var nodes = L.OSM.getNodes(xml),
         ways = L.OSM.getWays(xml);

    for (var i = 0; i < ways.length; i++) {
      var way = ways[i],
        latLngs = new Array(way.nodes.length);

      for (var j = 0; j < way.nodes.length; j++) {
        latLngs[j] = nodes[way.nodes[j]].latLng;
      }

      var layer;

      if (this.isWayArea(way)) {
        latLngs.pop(); // Remove last == first.
        layer = L.polygon(latLngs, this.options.styles.area);
      } else {
        layer = L.polyline(latLngs, this.options.styles.way);
      }

      layer.addTo(this);
      layer.feature = way;
    }

    for (var node_id in nodes) {
      var node = nodes[node_id];
      if (this.interestingNode(node)) {
        var layer = L.circleMarker(node.latLng, this.options.styles.node);

        layer.addTo(this);
        layer.feature = node;
      }
    }
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

  interestingNode: function (node) {
    for (var key in node.tags) {
      if (!~this.options.uninterestingTags.indexOf(key)) {
        return true;
      }
    }

    return false;
  }
});

L.Util.extend(L.OSM, {
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

  getWays: function (xml) {
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
        way_object.nodes[j] = nds[j].getAttribute("ref");
      }

      result.push(way_object);
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
