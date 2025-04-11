OSM.HistoryChangesetsLayer = L.FeatureGroup.extend({
  _changesets: new Map,

  _getChangesetStyle: function ({ isHighlighted }) {
    return {
      weight: isHighlighted ? 3 : 2,
      color: isHighlighted ? "#FF6600" : "#FF9500",
      fillColor: "#FFFFAF",
      fillOpacity: isHighlighted ? 0.3 : 0
    };
  },

  _updateChangesetStyle: function (changeset) {
    this.getLayer(changeset.id)?.setStyle(this._getChangesetStyle(changeset));
  },

  updateChangesets: function (map, changesets) {
    this._changesets = new Map(changesets.map(changeset => [changeset.id, changeset]));
    this.updateChangesetShapes(map);
  },

  updateChangesetShapes: function (map) {
    this.clearLayers();

    for (const changeset of this._changesets.values()) {
      const bottomLeft = map.project(L.latLng(changeset.bbox.minlat, changeset.bbox.minlon)),
            topRight = map.project(L.latLng(changeset.bbox.maxlat, changeset.bbox.maxlon)),
            width = topRight.x - bottomLeft.x,
            height = bottomLeft.y - topRight.y,
            minSize = 20; // Min width/height of changeset in pixels

      if (width < minSize) {
        bottomLeft.x -= ((minSize - width) / 2);
        topRight.x += ((minSize - width) / 2);
      }

      if (height < minSize) {
        bottomLeft.y += ((minSize - height) / 2);
        topRight.y -= ((minSize - height) / 2);
      }

      changeset.bounds = L.latLngBounds(map.unproject(bottomLeft),
                                        map.unproject(topRight));
    }

    const changesetEntries = [...this._changesets];
    changesetEntries.sort(([, a], [, b]) => {
      return b.bounds.getSize() - a.bounds.getSize();
    });
    this._changesets = new Map(changesetEntries);

    this.updateChangesetLocations(map);

    for (const changeset of this._changesets.values()) {
      delete changeset.isHighlighted;
      const rect = L.rectangle(changeset.bounds, this._getChangesetStyle(changeset));
      rect.id = changeset.id;
      rect.addTo(this);
    }
  },

  updateChangesetLocations: function (map) {
    const mapCenterLng = map.getCenter().lng;

    for (const changeset of this._changesets.values()) {
      const changesetSouthWest = changeset.bounds.getSouthWest();
      const changesetNorthEast = changeset.bounds.getNorthEast();
      const changesetCenterLng = (changesetSouthWest.lng + changesetNorthEast.lng) / 2;
      const shiftInWorldCircumferences = Math.round((changesetCenterLng - mapCenterLng) / 360);

      if (shiftInWorldCircumferences) {
        changesetSouthWest.lng -= shiftInWorldCircumferences * 360;
        changesetNorthEast.lng -= shiftInWorldCircumferences * 360;

        this.getLayer(changeset.id)?.setBounds(changeset.bounds);
      }
    }
  },

  toggleChangesetHighlight: function (id, state) {
    const changeset = this._changesets.get(id);
    if (!changeset) return;

    changeset.isHighlighted = state;
    this._updateChangesetStyle(changeset);
  },

  getLayerId: function (layer) {
    return layer.id;
  }
});
