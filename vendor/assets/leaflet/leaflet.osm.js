L.OSM = {};

L.OSM.PrefersColorSchemeWatcher = L.Class.extend({
  initialize: function (darkMode) {
    this._darkMode = darkMode;
  },

  watch: function () {
    if (!this._prefersDarkQuery) {
      this._darkModeWasEnabled = this._darkMode.isEnabled();
      this._prefersDarkQuery = matchMedia("(prefers-color-scheme: dark)");
      this._prefersDarkListener();
      L.DomEvent.on(this._prefersDarkQuery, 'change', this._prefersDarkListener, this);
    }
    return this;
  },
  unwatch: function () {
    if (this._prefersDarkQuery) {
      L.DomEvent.off(this._prefersDarkQuery, 'change', this._prefersDarkListener, this);
      this._prefersDarkQuery = undefined;
      this._darkMode.toggle(this._darkModeWasEnabled);
      this._darkModeWasEnabled = undefined;
    }
    return this;
  },

  _prefersDarkListener: function () {
    if (this._prefersDarkQuery) {
      this._darkMode.toggle(this._prefersDarkQuery.matches);
    }
  }
});

L.OSM.DarkMode = L.Class.extend({
  statics: {
    _darkModes: [],
    _layers: [],

    _addLayer: function (layer) {
      this._layers.push(layer);
      this._darkModes.forEach(function (darkMode) {
        darkMode._addLayer(layer);
      });
    },
    _removeLayer: function (layer) {
      this._darkModes.forEach(function (darkMode) {
        darkMode._removeLayer(layer);
      });
      var index = this._layers.indexOf(layer);
      if (index > -1) {
        this._layers.splice(index, 1);
      }
    }
  },

  options: {
    darkFilter: '',
    darkFilterMenuItems: []
  },

  initialize: function (options) {
    L.Util.setOptions(this, options);
    this._darkFilter = this.options.darkFilter;
    this._enabled = false;
    this._contextMenuUpdateHandlers = [];
    L.OSM.DarkMode._darkModes.push(this);
  },

  enable: function () {
    if (!this._enabled) {
      this._enabled = true;
      L.OSM.DarkMode._layers.forEach(function (layer) {
        this._enableLayerDarkVariant(layer);
      }, this);
      this._contextMenuUpdateHandlers.forEach(function (handler) {
        handler();
      });
    }
    return this;
  },
  disable: function () {
    if (this._enabled) {
      this._enabled = false;
      L.OSM.DarkMode._layers.forEach(function (layer) {
        this._disableLayerDarkVariant(layer);
      }, this);
      this._contextMenuUpdateHandlers.forEach(function (handler) {
        handler();
      });
    }
    return this;
  },
  toggle: function (requestEnable) {
    if (requestEnable !== undefined) {
      if (requestEnable) {
        this.enable();
      } else {
        this.disable();
      }
    } else {
      if (this._enabled) {
        this.disable();
      } else {
        this.enable();
      }
    }
    return this;
  },
  isEnabled: function () {
    return this._enabled;
  },

  // requires Leaflet.contextmenu plugin
  manageMapContextMenu: function (map) {
    var contextMenuElements = [];

    if (this.options.darkFilterMenuItems.length > 0) {
      var separator = map.contextmenu.addItem({
        separator: true
      });
      contextMenuElements.push(separator);
    }
    this.options.darkFilterMenuItems.forEach(function (menuItem) {
      var menuElement = map.contextmenu.addItem({
        text: menuItem.text,
        callback: function () {
          this._darkFilter = menuItem.filter;
          this._contextMenuUpdateHandlers.forEach(function (handler) {
            handler();
          });
          if (this._enabled) {
            L.OSM.DarkMode._layers.forEach(function (layer) {
              this._enableLayerDarkVariant(layer);
            }, this);
          }
        }.bind(this)
      });
      this._decorateContextMenuElement(menuElement, menuItem);
      contextMenuElements.push(menuElement);
    }, this);

    var updateContextMenuElements = function () {
      var numberOfLayersWithApplicableFilter = 0;
      map.eachLayer(function (layer) {
        if (layer instanceof L.OSM.TileLayer) {
          if (!layer.options.darkUrl) {
            numberOfLayersWithApplicableFilter++;
          }
        }
      });
      contextMenuElements.forEach(function (menuElement) {
        menuElement.hidden = !this._enabled || numberOfLayersWithApplicableFilter == 0;
        if ('filter' in menuElement.dataset) {
          menuElement.firstChild.checked = menuElement.dataset.filter === this._darkFilter;
        }
      }, this);
    }.bind(this);
    updateContextMenuElements();
    this._contextMenuUpdateHandlers.push(updateContextMenuElements);
    map.on("layeradd", updateContextMenuElements);
    map.on("layerremove", updateContextMenuElements);

    return this;
  },

  _addLayer: function (layer) {
    if (this._enabled) {
      this._enableLayerDarkVariant(layer);
    }
  },
  _removeLayer: function (layer) {
    if (this._enabled) {
      this._disableLayerDarkVariant(layer);
    }
  },

  _enableLayerDarkVariant: function (layer) {
    if (layer.options.darkUrl) {
      layer.setUrl(layer.options.darkUrl);
    } else {
      this._enableLayerDarkFilter(layer);
    }
  },
  _disableLayerDarkVariant: function (layer) {
    if (layer.options.darkUrl) {
      layer.setUrl(layer.options.url);
    } else {
      this._disableLayerDarkFilter(layer);
    }
  },

  _enableLayerDarkFilter: function (layer) {
    var container = layer.getContainer();
    if (container) {
      container.style.setProperty('filter', this._darkFilter);
    }
  },
  _disableLayerDarkFilter: function (layer) {
    var container = layer.getContainer();
    if (container) {
      layer.getContainer().style.removeProperty('filter');
    }
  },

  _decorateContextMenuElement: function (menuElement, menuItem) {
    menuElement.dataset.filter = menuItem.filter;
    var radio = document.createElement('input');
    radio.type = 'radio';
    radio.tabIndex = -1;
    radio.classList.add('leaflet-contextmenu-icon');
    radio.style.pointerEvents = 'none';
    radio.style.transform = 'scale(80%)';
    menuElement.prepend(radio, " ");
  }
});

L.OSM.TileLayer = L.TileLayer.extend({
  options: {
    url: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: '© <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap</a> contributors'
  },

  initialize: function (options) {
    options = L.Util.setOptions(this, options);
    L.TileLayer.prototype.initialize.call(this, options.url);

    this.on("add", function () {
      L.OSM.DarkMode._addLayer(this);
    }).on("remove", function () {
      L.OSM.DarkMode._removeLayer(this);
    });
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
    darkUrl: 'https://{s}.tile.thunderforest.com/transport-dark/{z}/{x}/{y}{r}.png?apikey={apikey}',
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
    url: 'https://tile.tracestrack.com/topo__/{z}/{x}/{y}.png?key={apikey}',
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
