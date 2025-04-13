OSM.HistoryChangesetsLayer = L.FeatureGroup.extend({
  _changesets: new Map,

  _getChangesetStyle: function ({ isHighlighted }) {
    let className = "changeset-in-sidebar-viewport";

    if (isHighlighted) {
      className += " changeset-highlighted";
    }

    return {
      weight: isHighlighted ? 3 : 2,
      color: "var(--changeset-border-color)",
      fillColor: "var(--changeset-fill-color)",
      fillOpacity: isHighlighted ? 0.3 : 0,
      className
    };
  },

  _updateChangesetStyle: function (changeset) {
    const rect = this.getLayer(changeset.id);
    if (!rect) return;

    const style = this._getChangesetStyle(changeset);
    rect.setStyle(style);
    // setStyle doesn't update css classes: https://github.com/leaflet/leaflet/issues/2662
    rect._path.classList.value = style.className;
    rect._path.classList.add("leaflet-interactive");
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
