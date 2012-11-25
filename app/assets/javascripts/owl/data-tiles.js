// Load tiled data and merge into single array.
// Requires jQuery for jsonp.
L.TileLayer.Data = L.TileLayer.extend({
    _requests: [],
    // Retrieve data from visible tiles.
    data: function() {
        var bounds = this.getTileBounds();
        if (!bounds) { return; }
        var result = [];
        for (k in this._tiles) {
            if (this._tiles[k].data == null) {
                continue;
            }
            var tile_x = k.split(':')[0], tile_y = k.split(':')[1];
            if (tile_x < bounds.min.x || tile_x > bounds.max.x || tile_y < bounds.min.y || tile_y > bounds.max.y) {
                // Tile is out of bounds (not visible) - skip it.
                continue;
            }
            result.push(this._tiles[k].data);
        }
        return result;
    },
    tiles: function() {
        var bounds = this.getTileBounds();
        if (!bounds) { return; }
        var result = {};
        for (k in this._tiles) {
            if (this._tiles[k].data == null) {
                continue;
            }
            var tile_x = k.split(':')[0], tile_y = k.split(':')[1];
            if (tile_x < bounds.min.x || tile_x > bounds.max.x || tile_y < bounds.min.y || tile_y > bounds.max.y) {
                // Tile is out of bounds (not visible) - skip it.
                continue;
            }
            result[k] = this._tiles[k];
        }
        return result;
    },
    _addTile: function(tilePoint, container) {
        var tile = { data: null };
        this._tiles[tilePoint.x + ':' + tilePoint.y] = tile;
        this._loadTile(tile, tilePoint);
    },
    _loadTile: function (tile, tilePoint) {
        var layer = this;
        this._requests.push($.ajax({
            url: this.getTileUrl(tilePoint),
            dataType: $.browser.msie ? 'jsonp' : 'json',
            success: function(data) {
                tile.data = data;
                layer.fire('tileload', {
                    tile: tile
                });
                layer._tileLoaded();
            },
            error: function() {
                layer._tileLoaded();
            }
        }));
    },
    _resetCallback: function() {
        L.TileLayer.prototype._resetCallback.apply(this, arguments);
        for (i in this._requests) {
            this._requests[i].abort();
        }
        this._requests = [];
    },
    _update: function() {
        if (!this._map || (this._map._panTransition && this._map._panTransition._inProgress)) { return; }

        // Geometry tiles are only available for zoom level 16 so beyond that we need to offset.
        // TODO: make this configurable.
        if (this._map.getZoom() > 16) {
          this.options.zoomOffset = 16 - this._map.getZoom();
          // Modified tile size: ZL17 -> 512, ZL19 -> 1024
          this.options.tileSize = Math.pow(2, 8 - this.options.zoomOffset);
        } else {
          // Regular settings.
          this.options.zoomOffset = 0;
          this.options.tileSize = 256;
        }

        L.TileLayer.prototype._update.apply(this, arguments);
    },
    getTileBounds: function() {
        if (!this._map) { return; }
        var bounds = this._map.getPixelBounds(),
          zoom = this._map.getZoom(), tileSize = this.options.tileSize;
        var nwTilePoint = new L.Point(
          Math.floor(bounds.min.x / tileSize),
          Math.floor(bounds.min.y / tileSize)),
        seTilePoint = new L.Point(
          Math.floor(bounds.max.x / tileSize),
          Math.floor(bounds.max.y / tileSize));
        return new L.Bounds(nwTilePoint, seTilePoint);
    }
});
