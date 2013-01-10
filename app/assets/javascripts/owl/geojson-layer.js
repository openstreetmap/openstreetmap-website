L.OWL = {};

L.OWL.GeoJSON = L.FeatureGroup.extend({
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
    this._refresh();
  },

  _handleMapChange: function (e) {
    var url = this._getUrlForTilerange();
    if (url == this.currentUrl) {
      // No change in tile range - no need to do the AJAX call.
      return;
    }
    this.currentOffset = 0;
    this._refresh();
  },

  _refresh: function () {
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
        this.osmElements = {};
        this._removeObjectLayers();
        this._addGeoJSON(geojson);
        this.fire('loaded', geojson);
      },
      error: function() {
      }
    });
  },

  changesetList: function () {
    var list = [];
    $.each(this.changesets, function (k, v) { list.push(v); });
    list.sort(function (a, b) {
      return a.created_at > b.created_at ? -1 : 1;
    });
    return list;
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

  // Add GeoJSON features.
  _addGeoJSON: function (geojson) {
    this.clearLayers();
    this.changesets = {};

    var layer = this;

    $.each(geojson['features'], function (index, changeset) {
      layer.owlObjectLayers[changeset.properties.id] = [];
      layer.changesets[changeset.properties.id] = changeset.properties;

      var changeById = {};
      $.each(changeset.properties.changes, function (index, change) {
        change.diffTags = layer.diffTags(change.tags, change.prev_tags);
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
          layer.addChangeFeatureLayer(change, changeFeature.features[0],
            changeFeature.features.length > 1 ? changeFeature.features[1] : null);
        }
      });
    });
  },

  // Prepares a GeoJSON layer for a given change feature and adds it to the map.
  addChangeFeatureLayer: function (change, geojson, prev_geojson) {
    if (change.id != this.osmElements[change.el_id].id) {
      return;
    }

    var layer = this;
    var style = this.styles[this._getStyleName(change)];

    var changeLayer = new L.GeoJSON(geojson, {style: style,
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
    }

    changeLayer.on('mouseover', function (e) {
        e.target.setStyle(this.styles.hover);
        highlightChangesetItem(change.changeset_id);
    }, this);

    changeLayer.on('mouseout', function (e) {
        e.target.setStyle(style);
        unhighlightChangesetItem(change.changeset_id);
    });

    changeLayer.on('click', function (e) {
      this.fire('change_clicked', {
          event: e,
          changesets: this.changesets,
          clickedChange: change,
          geomLayer: changeLayer,
          prevGeomLayer: prevGeomLayer
      });
    }, this);

    this.owlObjectLayers[change.changeset_id].push(changeLayer);
    this.addLayer(changeLayer);
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
      // Modified tile size: ZL17 -> 512, ZL19 -> 1024
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
      // Modified tile size: ZL17 -> 512, ZL19 -> 1024
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
