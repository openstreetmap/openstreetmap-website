L.OWL = {};

L.OWL.GeoJSON = L.FeatureGroup.extend({
  minZoomLevel: 12,
  pageSize: 15,
  currentOffset: 0,
  changesets: {},
  owlObjectLayers: {},
  styles: {},
  currentUrl: null,
  osmElements: {},

  initialize: function (options) {
    this.styles = options.styles;
    L.FeatureGroup.prototype.initialize.apply(this, arguments);
  },

  onAdd: function (map) {
    this._map = map;
    map.on('moveend', this._handleMapChange, this);
  },

  onRemove: function (map) {
    map.off('moveend', this._handleMapChange, this);
    this._removeObjectLayers();
  },

  nextPage: function() {
    this.currentOffset += this.pageSize;
    this._loadMore();
  },

  showCurrentGeom: function (changeId) {
    var change = this.findChange(changeId);
    if (change.prevGeomLayer && this._map.hasLayer(change.prevGeomLayer)) {
      this._map.removeLayer(change.prevGeomLayer);
    }
    if (change.currentGeomLayer && !this._map.hasLayer(change.currentGeomLayer)) {
      this._map.addLayer(change.currentGeomLayer);
    }
  },

  showPrevGeom: function (changeId) {
    var change = this.findChange(changeId);
    if (change.currentGeomLayer && this._map.hasLayer(change.currentGeomLayer)) {
      this._map.removeLayer(change.currentGeomLayer);
    }
    if (change.prevGeomLayer && !this._map.hasLayer(change.prevGeomLayer)) {
      this._map.addLayer(change.prevGeomLayer);
    }
  },

  findChange: function (changeId) {
    var result = null;
    $.each (this.changesets, function (id, changeset) {
      if (changeId in changeset.changes) {
        result = changeset.changes[changeId];
        return false;
      }
    });
    return result;
  },

  // Returns the layer to the starting state - removes all features, resets internal structures etc.
  reset: function () {
    this.fire('reset');
    this.changesets = {};
    this.osmElements = {};
    this._removeObjectLayers();
  },

  highlightChangesetFeatures: function (changeset_id) {
    var layer = this;
    if (changeset_id in this.owlObjectLayers) {
      $.each(this.owlObjectLayers[changeset_id], function(index, obj) {
        if ('setStyle' in obj) {
          obj.setStyle(layer.styles.hover);
        }
      });
    }
  },

  unhighlightChangesetFeatures: function (changeset_id) {
    if (changeset_id in this.owlObjectLayers) {
      $.each(this.owlObjectLayers[changeset_id], function(index, obj) {
        if ('resetStyle' in obj) {
          obj.setStyle(obj.options.style);
        }
      });
    }
  },

  highlightChangeFeature: function (changeId) {
    var change = this.findChange(changeId);
    if (change.currentGeomLayer) {
      change.currentGeomLayer.setStyle(this.styles.hover);
    } else if (change.prevGeomLayer) {
      change.prevGeomLayer.setStyle(this.styles.hover);
    }
  },

  unhighlightChangeFeature: function (changeId) {
    var change = this.findChange(changeId);
    if (change.currentGeomLayer) {
      change.currentGeomLayer.setStyle(change.currentGeomLayer.options.style);
    } else if (change.prevGeomLayer) {
      change.prevGeomLayer.setStyle(change.prevGeomLayer.options.style);
    }
  },

  _handleMapChange: function (e) {
    var url = this._getUrlForTilerange();
    if (url == this.currentUrl) {
      // No change in tile range - no need to do the AJAX call.
      return;
    }
    this.currentOffset = 0;
    this._loadMore(true);
  },

  _loadMore: function (doReset) {
    if (doReset) {
      this.reset();
    }

    if (this._map.getZoom() < this.minZoomLevel) {
      this.fire('notloading');
      return;
    }

    this.fire('loading');

    var requestUrl = this._getUrlForTilerange();
    $.ajax({
      context: this,
      url: requestUrl,
      dataType: 'jsonp',
      success: function(geojson, status, xhr) {
        var url = this._getUrlForTilerange();
        if (url != requestUrl) {
          // Ignore response that is not applicable to the current viewport.
          return;
        }
        this.currentUrl = url;
        var loadedChangesets = this._processResponse(geojson);
        this.fire('loaded', {
          changesets: loadedChangesets,
          gotMore: loadedChangesets.length == this.pageSize
        });
      },
      error: function() {
      }
    }, this);
  },

  // Add GeoJSON features, build internal structures.
  _processResponse: function (geojson) {
    var layer = this;
    var loadedChangesets = [];

    $.each(geojson['features'], function (index, changeset) {
      layer.owlObjectLayers[changeset.properties.id] = [];
      layer.changesets[changeset.properties.id] = changeset.properties;
      loadedChangesets.push(changeset.properties);

      var changeById = {};
      $.each(changeset.properties.changes, function (index, change) {
        if (change.el_action != 'AFFECT') {
          change.diffTags = layer.diffTags(change.tags, change.prev_tags);
        } else {
          change.diffTags = layer.diffTags(change.tags, change.tags);
        }
        if (!(change.el_id in layer.osmElements)) {
          layer.osmElements[change.el_id] = change;
        } else if (change.version > layer.osmElements[change.el_id].version) {
          layer.osmElements[change.el_id] = change;
        }
        changeById[change.id] = change;
        layer.changesets[changeset.properties.id].changes = changeById;
      });
    });

    $.each(geojson['features'].reverse(), function (index, changeset) {
      $.each(changeset['features'].reverse(), function (index, changeFeature) {
        var change = layer.changesets[changeFeature.properties.changeset_id].changes[changeFeature.properties.change_id];
        if (changeFeature.features.length > 0) {
          var geojson = null, prevGeojson = null;
          if (changeFeature.features[0].properties.type == 'prev') {
            prevGeojson = changeFeature.features[0];
          } else {
            geojson = changeFeature.features[0];
            if (changeFeature.features.length > 1) {
              prevGeojson = changeFeature.features[1];
            }
          }
          layer.addChangeFeatureLayer(change, geojson, prevGeojson);
        }
      });
    });

    loadedChangesets.sort(function (a, b) {
      return a.created_at > b.created_at ? -1 : 1;
    });

    return loadedChangesets;
  },

  // Prepares a GeoJSON layer for a given change feature and adds it to the map.
  addChangeFeatureLayer: function (change, geojson, prev_geojson) {
    if (change.id != this.osmElements[change.el_id].id) {
      //return;
    }

    var layer = this;
    var style = this.styles[this._getStyleName(change)];

    var currentGeomLayer = new L.GeoJSON(geojson, {style: style,
      pointToLayer: function (geojson, latlng) {
        return L.circleMarker(latlng, style);
      }
    }), prevGeomLayer = null;

    if (prev_geojson != null) {
      prevGeomLayer = new L.GeoJSON(prev_geojson, {style: style,
        pointToLayer: function (geojson, latlng) {
          return L.circleMarker(latlng, style);
        }
      });
      this.owlObjectLayers[change.changeset_id].push(prevGeomLayer);
      change.prevGeomLayer = prevGeomLayer;
    }

    currentGeomLayer.on('mouseover', function (e) {
        e.target.setStyle(this.styles.hover);
        this.fire('changemouseover', {
          event: e,
          change: change
        });
    }, this);

    currentGeomLayer.on('mouseout', function (e) {
        e.target.setStyle(style);
        this.fire('changemouseout', {
          event: e,
          change: change
        });
    }, this);

    currentGeomLayer.on('click', function (e) {
      this.fire('change_clicked', {
        event: e,
        changesets: this.changesets,
        clickedChange: change,
        currentGeomLayer: currentGeomLayer,
        prevGeomLayer: prevGeomLayer
      });
    }, this);

    this.owlObjectLayers[change.changeset_id].push(currentGeomLayer);
    change.currentGeomLayer = currentGeomLayer;
    this.addLayer(currentGeomLayer);
  },

  _getStyleName: function (change) {
    var name = {'N': 'node_', 'W': 'way_'}[change['el_type']];
    name += change['el_action'].toLowerCase();
    return name;
  },

  _removeObjectLayers: function () {
    var layer = this;
    $.each(this.owlObjectLayers, function (changeset_id) {
      $.each(layer.owlObjectLayers[changeset_id], function (index, l) {
        layer._map.removeLayer(l);
      });
    });
    this.owlObjectLayers = {};
  },

  _getUrlForTilerange: function () {
    var tileSize, zoom;
    if (this._map.getZoom() > 16) {
      // Modified tile size: ZL17 -> 512, ZL18 -> 1024
      tileSize = Math.pow(2, 8 - (16 - this._map.getZoom()));
      zoom = 16;
    } else {
      // Regular settings.
      tileSize = 256;
      zoom = this._map.getZoom();
    }
    var bounds = this._map.getPixelBounds(),
      nwTilePoint = new L.Point(
        Math.floor(bounds.min.x / tileSize),
        Math.floor(bounds.min.y / tileSize)),
      seTilePoint = new L.Point(
        Math.floor(bounds.max.x / tileSize),
        Math.floor(bounds.max.y / tileSize));
    return OSM.OWL_API_URL + 'changesets/'
        + zoom + '/'
        + nwTilePoint.x + '/' + nwTilePoint.y + '/'
        + seTilePoint.x + '/' + seTilePoint.y + '.geojson?limit=' + this.pageSize + '&offset=' + this.currentOffset;
  },

  getAtomUrlForTilerange: function () {
    var tileSize, zoom;
    if (this._map.getZoom() > 16) {
      // Modified tile size: ZL17 -> 512, ZL18 -> 1024
      tileSize = Math.pow(2, 8 - (16 - this._map.getZoom()));
      zoom = 16;
    } else {
      // Regular settings.
      tileSize = 256;
      zoom = this._map.getZoom();
    }
    var bounds = this._map.getPixelBounds(),
      nwTilePoint = new L.Point(
        Math.floor(bounds.min.x / tileSize),
        Math.floor(bounds.min.y / tileSize)),
      seTilePoint = new L.Point(
        Math.floor(bounds.max.x / tileSize),
        Math.floor(bounds.max.y / tileSize));
    return OSM.OWL_API_URL + 'changesets/'
        + zoom + '/'
        + nwTilePoint.x + '/' + nwTilePoint.y + '/'
        + seTilePoint.x + '/' + seTilePoint.y + '.atom';
  },

  // Calculates a diff between two hashes containing tags.
  diffTags: function (tags, prev_tags) {
    var result = {added: {}, removed: {}, same: {}, modified: {}};
    $.each(tags, function (k, v) {
      if (prev_tags && k in prev_tags) {
        if (v == prev_tags[k]) {
          result.same[k] = v;
        } else {
          result.modified[k] = [v, prev_tags[k]];
        }
      } else {
        result.added[k] = v;
      }
    });
    if (prev_tags) {
      $.each(prev_tags, function (k, v) {
        if (!(k in tags)) {
          result.removed[k] = v;
        }
      });
    }
    return result;
  }
});
