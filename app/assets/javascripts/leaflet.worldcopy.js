// worldCopyJump moves the map pane by a whole world at the antimeridian without
// notifying layers of the discontinuity. Rebase wrapped tiles and update the
// MapLibre canvas immediately so they remain in the viewport during the jump.
{
  const worldTileColumns = function (layer, zoom) {
    const bounds = layer._map.getPixelWorldBounds(zoom),
          columns = bounds && (bounds.getSize().x / layer.getTileSize().x);
    // Only reuse tiles when a world contains a whole number of columns.
    return Number.isInteger(columns) ? columns : null;
  };

  const shiftGridLayer = function (layer, worlds) {
    // Tiles from noWrap layers are not interchangeable between world copies.
    if (!layer._wrapX) return;

    const columns = {};
    for (const key in layer._tiles) {
      const zoom = layer._tiles[key].coords.z;
      if (!(zoom in columns)) columns[zoom] = worldTileColumns(layer, zoom);
      if (columns[zoom] === null) return;
    }

    const tiles = {};
    for (const key in layer._tiles) {
      const tile = layer._tiles[key],
            columnShift = worlds * columns[tile.coords.z],
            position = L.DomUtil.getPosition(tile.el);

      tile.coords.x -= columnShift;
      tiles[layer._tileCoordsToKey(tile.coords)] = tile;
      L.DomUtil.setPosition(tile.el, position.subtract([columnShift * layer.getTileSize().x, 0]));
    }
    layer._tiles = tiles;
  };

  const followWorldCopyJump = function (map, worlds) {
    map.eachLayer(function (layer) {
      if (layer instanceof L.GridLayer) {
        shiftGridLayer(layer, worlds);
      } else if (L.MaplibreGL && layer instanceof L.MaplibreGL) {
        layer._update();
      }
    });
  };

  const onDragStart = L.Map.Drag.prototype._onDragStart,
        onPreDragWrap = L.Map.Drag.prototype._onPreDragWrap,
        onDrag = L.Map.Drag.prototype._onDrag;

  L.Map.Drag.include({
    _onDragStart: function () {
      this._wrapOffset = 0;
      this._wrappedWorlds = 0;
      onDragStart.call(this);
    },

    _onPreDragWrap: function () {
      const unwrappedX = this._draggable._newPos.x;
      onPreDragWrap.call(this);
      const offset = this._draggable._newPos.x - unwrappedX;
      this._wrappedWorlds += Math.round((offset - this._wrapOffset) / this._worldWidth);
      this._wrapOffset = offset;
    },

    _onDrag: function (e) {
      // Draggable moves the pane after predrag and before drag.
      if (this._wrappedWorlds) {
        followWorldCopyJump(this._map, this._wrappedWorlds);
        this._wrappedWorlds = 0;
      }
      onDrag.call(this, e);
    }
  });
}
