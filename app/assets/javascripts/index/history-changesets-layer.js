OSM.HistoryChangesetsLayer = L.FeatureGroup.extend({
  _getSidebarRelativeClassName: function ({ sidebarRelativePosition }) {
    if (sidebarRelativePosition > 0) {
      return "changeset-above-sidebar-viewport";
    } else if (sidebarRelativePosition < 0) {
      return "changeset-below-sidebar-viewport";
    } else {
      return "changeset-in-sidebar-viewport";
    }
  },

  _getAreaStyle: function (changeset) {
    return {
      weight: 0,
      fillOpacity: 0,
      className: this._getSidebarRelativeClassName(changeset)
    };
  },

  _getBorderStyle: function (changeset) {
    return {
      weight: 2,
      color: "var(--changeset-border-color)",
      fill: false,
      className: this._getSidebarRelativeClassName(changeset)
    };
  },

  _getHighlightStyle: function (changeset) {
    return {
      interactive: false,
      weight: 4,
      color: "var(--changeset-border-color)",
      fillColor: "var(--changeset-fill-color)",
      fillOpacity: 0.3,
      className: this._getSidebarRelativeClassName(changeset) + " changeset-highlighted"
    };
  },

  updateChangesets: function (map, changesets) {
    this._changesets = new Map(changesets.map(changeset => [changeset.id, changeset]));
    this.updateChangesetShapes(map);
  },

  updateChangesetShapes: function (map) {
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

    this.updateChangesetLocations(map);
    this.reorderChangesets();
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

        this._areaLayer.getLayer(changeset.id)?.setBounds(changeset.bounds);
        this._borderLayer.getLayer(changeset.id)?.setBounds(changeset.bounds);
        this._highlightLayer.getLayer(changeset.id)?.setBounds(changeset.bounds);
      }
    }
  },

  reorderChangesets: function () {
    const changesetEntries = [...this._changesets];
    changesetEntries.sort(([, a], [, b]) => {
      const aInViewport = !a.sidebarRelativePosition;
      const bInViewport = !b.sidebarRelativePosition;
      if (aInViewport !== bInViewport) return aInViewport - bInViewport;
      return b.bounds.getSize() - a.bounds.getSize();
    });
    this._changesets = new Map(changesetEntries);

    this._areaLayer.clearLayers();
    this._borderLayer.clearLayers();
    this._highlightLayer.clearLayers();

    for (const changeset of this._changesets.values()) {
      const rect = L.rectangle(changeset.bounds, this._getAreaStyle(changeset));
      rect.id = changeset.id;
      rect.addTo(this._areaLayer);
    }

    for (const changeset of this._changesets.values()) {
      const rect = L.rectangle(changeset.bounds, this._getBorderStyle(changeset));
      rect.id = changeset.id;
      rect.addTo(this._borderLayer);
    }
  },

  toggleChangesetHighlight: function (id, state) {
    const changeset = this._changesets.get(id);
    if (!changeset) return;

    let highlightRect = this._highlightLayer.getLayer(id);
    if (!state && highlightRect) {
      this._highlightLayer.removeLayer(highlightRect);
    }
    if (state && !highlightRect) {
      highlightRect = L.rectangle(changeset.bounds, this._getHighlightStyle(changeset));
      highlightRect.id = id;
      this._highlightLayer.addLayer(highlightRect);
    }
  },

  setChangesetSidebarRelativePosition: function (id, state) {
    const changeset = this._changesets.get(id);
    if (!changeset) return;
    changeset.sidebarRelativePosition = state;
  }
});

OSM.HistoryChangesetsLayer.addInitHook(function () {
  this._changesets = new Map;

  this._areaLayer = L.featureGroup().addTo(this);
  this._borderLayer = L.featureGroup().addTo(this);
  this._highlightLayer = L.featureGroup().addTo(this);

  this._areaLayer.getLayerId = (layer) => layer.id;
  this._borderLayer.getLayerId = (layer) => layer.id;
  this._highlightLayer.getLayerId = (layer) => layer.id;
});
