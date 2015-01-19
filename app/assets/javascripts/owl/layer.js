L.OWL = {};

L.OWL.Layer = L.TileLayer.GeoJSON.extend({
  minZoomLevel: 12,
  pageSize: 15,
  currentOffset: 0,
  owlObjectLayers: {},
  changes: {},
  styles: {},
  elements: {},

  initialize: function(options) {
    this.styles = options.styles;
    L.TileLayer.GeoJSON.prototype.initialize.call(this, OSM.OWL_API_URL + 'changesets/{z}/{x}/{y}.json', {
      unloadInvisibleTiles: true,
      unique: function(feature) {
        return feature.properties.changeset_id + '_' + feature.properties.change_id;
      }
    });
  },

  getChangeset: function(id) {
    return this._getChangesetsFromTiles()[id];
  },

  _getChangesetsFromTiles: function() {
    //console.log('called _getChangesetsFromTiles')
    var changesets = {};
    var layer = this;
    $.each(this._tiles, function(tileId, tile) {
      if (tile.datum == null) {
        return;
      }
      $.each(tile.datum, function(index, changeset) {
        if (!(changeset.id in changesets)) {
          changesets[changeset.id] = $.extend({}, changeset);
          changesets[changeset.id].changes = {};
        }

        $.each(changeset.changes, function(changeIndex, change) {
          if (change.id in changesets[changeset.id].changes) {
            changesets[changeset.id].changes[change.id] = change;
          } else {
            changesets[changeset.id].changes[change.id] = change;
          }
        });
        //changesets[changeset.id].changes = $.extend(changesets[changeset.id].changes, changeset.changes);
        //changesets[changeset.id].changes = changesets[changeset.id].changes.concat(changeset.changes);
      });
    });
    return changesets;
  },

  onAdd: function(map) {
    var layer = this;
    this._map = map;
    map.on('viewreset', function(e) {
      layer.reset();
    });
    layer.fire('reset');
    L.TileLayer.GeoJSON.prototype.onAdd.apply(this, arguments);
  },

  onRemove: function(map) {
    //map.off('moveend', this._handleMapChange, this);
    //this._removeObjectLayers();
    L.TileLayer.GeoJSON.prototype.onRemove.apply(this, arguments);
  },

  showCurrentGeom: function(changeId) {
    var change = this.findChange(changeId);
    if (change.prevGeomLayer && this._map.hasLayer(change.prevGeomLayer)) {
      this._map.removeLayer(change.prevGeomLayer);
    }
    if (change.currentGeomLayer && !this._map.hasLayer(change.currentGeomLayer)) {
      this._map.addLayer(change.currentGeomLayer);
    }
  },

  showPrevGeom: function(changeId) {
    var change = this.findChange(changeId);
    if (change.currentGeomLayer && this._map.hasLayer(change.currentGeomLayer)) {
      this._map.removeLayer(change.currentGeomLayer);
    }
    if (change.prevGeomLayer && !this._map.hasLayer(change.prevGeomLayer)) {
      this._map.addLayer(change.prevGeomLayer);
    }
  },

  findChange: function(changeId) {
    var index = changeId.split('|')[1];
    var result = null;
    $.each(this._getChangesetsFromTiles(), function(id, changeset) {
      result = changeset.changes[index];
      return false;
    });
    if (result == null) {
      console.error('No change for id: ' + changeId);
      //return;
    }
    return result;
  },

  // Returns the layer to the starting state - removes all features, resets internal structures etc.
  reset: function() {
    this.geojsonLayer.clearLayers();
    this.changesets = {};
    this.fire('reset');
    //this._removeObjectLayers();
  },

  highlightChangesetFeatures: function(changeset_id) {
    var layer = this;
    if (changeset_id in this.owlObjectLayers) {
      $.each(this.owlObjectLayers[changeset_id], function(index, obj) {
        if ('setStyle' in obj) {
          obj.setStyle(layer.styles.hover);
        }
      });
    }
  },

  unhighlightChangesetFeatures: function(changeset_id) {
    if (changeset_id in this.owlObjectLayers) {
      $.each(this.owlObjectLayers[changeset_id], function(index, obj) {
        if ('resetStyle' in obj) {
          obj.setStyle(obj.options.style);
        }
      });
    }
  },

  highlightChangeFeature: function(changeId) {
    var change = this.findChange(changeId);
    if (change.currentGeomLayer) {
      change.currentGeomLayer.setStyle(this.styles.hover);
    } else if (change.prevGeomLayer) {
      change.prevGeomLayer.setStyle(this.styles.hover);
    }
  },

  unhighlightChangeFeature: function(changeId) {
    var change = this.findChange(changeId);
    if (change.currentGeomLayer) {
      change.currentGeomLayer.setStyle(change.currentGeomLayer.options.style);
    } else if (change.prevGeomLayer) {
      change.prevGeomLayer.setStyle(change.prevGeomLayer.options.style);
    }
  },

  _elementAlreadyShown: function (el_type, el_id) {
    return this.elements[el_type + el_id] !== undefined;
  },

  // Add GeoJSON features, build internal structures.
  _tileLoaded: function(tile, tilePoint) {
    if (tile.datum == null) {
      return;
    }

    console.log('loaded tile', tilePoint)

    var layer = this;
    $.each(tile.datum, function(index, changeset) {
      layer.owlObjectLayers[changeset.id] = [];

      $.each(changeset.changes, function(index, change) {
        change.changeset_id = changeset.id;
        change.uid = changeset.id + '|' + change.id;
        if (change.geom) {
          change.geom = L.GeoJSON.asFeature(change.geom);
        }
        if (change.prev_geom) {
          change.prev_geom = L.GeoJSON.asFeature(change.prev_geom);
        }

        if (change.action != 'AFFECT') {
          change.diffTags = diffTags(change.tags, change.prev_tags);
        } else {
          change.diffTags = diffTags(change.tags, change.tags);
        }

        //console.log('adding change for el_id', change.el_id, change)
        layer.addChangeFeatureLayer(changeset, change);
      });
    });

    this.fire('loaded', {
      changesets: this._getChangesetsFromTiles(),
      gotMore: true,
      loadedAllTiles: layer._requests.length === 0
    });
  },

  _removeTile: function(key) {
    var layer = this;
    var tile = this._tiles[key];
    if (tile.datum != null) {
      $.each(tile.datum, function(index, changeset) {
        $.each(changeset.changes, function(index, change) {
          //console.log('removing');
          //console.log(change.geom.geometry.coordinates);
          layer.geojsonLayer.hasLayer(change.currentGeomLayer) && layer.geojsonLayer.removeLayer(change.currentGeomLayer);
          layer.geojsonLayer.hasLayer(change.prevGeomLayer) && layer.geojsonLayer.removeLayer(change.prevGeomLayer);
        });
      });
    }
    L.TileLayer.GeoJSON.prototype._removeTile.apply(this, arguments);
  },

  // Prepares a GeoJSON layer for a given change feature and adds it to the map.
  addChangeFeatureLayer: function(changeset, change) {
    if (this._elementAlreadyShown(change.el_type, change.el_id)) {
      // TODO should we show only one change for an element or all of them or...?
      //console.log('Already shown', change);
      //return;
    }
    this.elements[change.el_type + change.el_id] = change.tstamp;
    var layer = this;
    var style = this._getStyle(change);

    var currentGeomLayer = new L.GeoJSON(change.geom, {
      style: style,
      pointToLayer: function(geojson, latlng) {
        return L.circleMarker(latlng, style);
      }
    }),
      prevGeomLayer = null;

    if (change.prev_geom != null) {
      prevGeomLayer = new L.GeoJSON(change.prev_geom, {
        style: style,
        pointToLayer: function(geojson, latlng) {
          return L.circleMarker(latlng, style);
        }
      });
      this.owlObjectLayers[change.changeset_id].push(prevGeomLayer);
      change.prevGeomLayer = prevGeomLayer;
      prevGeomLayer.on('mouseover', function(e) {
        e.target.setStyle(this.styles.hover);
        this.fire('changemouseover', {
          event: e,
          change: change
        });
      }, this);

      prevGeomLayer.on('mouseout', function(e) {
        e.target.setStyle(style);
        this.fire('changemouseout', {
          event: e,
          change: change
        });
      }, this);

      prevGeomLayer.on('click', function(e) {
        this.fire('change_clicked', {
          event: e,
          changesets: this.changesets,
          clickedChange: change,
          currentGeomLayer: currentGeomLayer,
          prevGeomLayer: prevGeomLayer
        });
      }, this);
    }

    currentGeomLayer.on('mouseover', function(e) {
      e.target.setStyle(this.styles.hover);
      this.fire('changemouseover', {
        event: e,
        change: change
      });
    }, this);

    currentGeomLayer.on('mouseout', function(e) {
      e.target.setStyle(style);
      this.fire('changemouseout', {
        event: e,
        change: change
      });
    }, this);

    currentGeomLayer.on('click', function(e) {
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
    this.geojsonLayer.addLayer(currentGeomLayer);
    //console.log('adding');
    //console.log(change.geom.geometry.coordinates);
    if (change.action == 'DELETE') {
      this.showPrevGeom(change.uid);
    }
  },

  _getStyle: function(change) {
    var geomType = change.geom ? change.geom.geometry.type : null;
    if (change.prev_geom) {
      geomType = change.prev_geom.geometry.type;
    }
    return $.extend({}, this.styles[geomType], this.styles['action_' + change['action']]);
  },

  _removeObjectLayers: function() {
    var layer = this;
    $.each(this.owlObjectLayers, function(changeset_id) {
      $.each(layer.owlObjectLayers[changeset_id], function(index, l) {
        layer._map.removeLayer(l);
      });
    });
    this.owlObjectLayers = {};
  }
});
