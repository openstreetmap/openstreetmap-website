L.OWL = {};

L.OWL.GeoJSON = L.FeatureGroup.extend({
  pageSize: 15,
  currentOffset: 0,
  changes: {},
  owlObjectLayers: {},
  styles: {},

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
  },

  _refresh: function () {
    $.ajax({
      context: this,
      url: this._getUrlForTilerange(),
      dataType: 'jsonp',
      success: function(geojson) {
        this._removeObjectLayers();
        this.addGeoJSON(geojson);
        this.fire('loaded', geojson);
      },
      error: function() {
      }
    });
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
  addGeoJSON: function (geojson) {
    this.clearLayers();
    var layer = this;
    $.each(geojson['features'], function (index, changeset) {
      layer.owlObjectLayers[changeset.properties.id] = [];
      $.each(changeset.properties.changes, function (index, change) {
        change.diffTags = diffTags(change.tags, change.prev_tags);
        layer.changes[change.id] = change;
      });
      $.each(changeset['features'], function (index, change) {
        layer.addChangeFeatureLayer(change, change.features[0]);
        if (change.features.length > 1) {
          layer.addChangeFeatureLayer(change, change.features[1]);
        }
      });
    });
  },

  // Prepares a GeoJSON layer for a given change feature and adds it to the map.
  addChangeFeatureLayer: function (change, geojson) {
    var active = geojson.properties.type == 'current';

    if (!active && this.changes[change.properties.change_id].el_action != 'DELETE') {
      return;
    }

    var layer = this;
    var style = active ? this.styles.normal : this.styles.inactive;
    var realLayer = new L.GeoJSON(geojson, {style: style,
      pointToLayer: function (geojson, latlng) {
        return L.circleMarker(latlng, layer.styles.circleMarker);
      }
    });

    realLayer.on('mouseover', function (e) {
        e.target.setStyle(this.styles.hover);
        highlightChangesetItem(change.properties.changeset_id);
    }, this);
    realLayer.on('mouseout', function (e) {
        e.target.setStyle(style);
        unhighlightChangesetItem(change.properties.changeset_id);
    });
    realLayer.on('click', function (e) {
      L.popup({maxHeight: 666, maxWidth: 666})
        .setLatLng(e.latlng)
        .setContent(JST["templates/change"]({change: this.changes[change.properties.change_id]}))
        .openOn(this._map);
    }, this);
    this.owlObjectLayers[change.properties.changeset_id].push(realLayer);
    this.addLayer(realLayer);
  },

  _handleMapChange: function (e) {
    this.currentOffset = 0;
    this._refresh();
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
  }
});
