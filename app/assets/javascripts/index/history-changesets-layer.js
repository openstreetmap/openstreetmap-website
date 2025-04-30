OSM.HistoryChangesetBboxLayer = L.FeatureGroup.extend({
  getLayerId: function (layer) {
    return layer.id;
  },

  addChangesetLayer: function (changeset) {
    const style = this._getChangesetStyle(changeset);
    const rectangle = L.rectangle(changeset.bounds, style);
    rectangle.id = changeset.id;
    return this.addLayer(rectangle);
  },

  updateChangesetLayerBounds: function (changeset) {
    this.getLayer(changeset.id)?.setBounds(changeset.bounds);
  },

  _getSidebarRelativeClassName: function ({ sidebarRelativePosition }) {
    if (sidebarRelativePosition > 0) {
      return "changeset-above-sidebar-viewport";
    } else if (sidebarRelativePosition < 0) {
      return "changeset-below-sidebar-viewport";
    } else {
      return "changeset-in-sidebar-viewport";
    }
  }
});

OSM.HistoryChangesetBboxAreaLayer = OSM.HistoryChangesetBboxLayer.extend({
  _getChangesetStyle: function (changeset) {
    return {
      weight: 0,
      fillOpacity: 0,
      className: this._getSidebarRelativeClassName(changeset)
    };
  }
});

OSM.HistoryChangesetBboxOutlineLayer = OSM.HistoryChangesetBboxLayer.extend({
  _getChangesetStyle: function (changeset) {
    return {
      weight: 4,
      color: "var(--changeset-outline-color)",
      fill: false,
      className: this._getSidebarRelativeClassName(changeset)
    };
  }
});

OSM.HistoryChangesetBboxBorderLayer = OSM.HistoryChangesetBboxLayer.extend({
  _getChangesetStyle: function (changeset) {
    return {
      weight: 2,
      color: "var(--changeset-border-color)",
      fill: false,
      className: this._getSidebarRelativeClassName(changeset)
    };
  }
});

OSM.HistoryChangesetBboxHighlightLayer = OSM.HistoryChangesetBboxLayer.extend({
  _getChangesetStyle: function (changeset) {
    return {
      interactive: false,
      weight: 4,
      color: "var(--changeset-border-color)",
      fillColor: "var(--changeset-fill-color)",
      fillOpacity: 0.3,
      className: this._getSidebarRelativeClassName(changeset) + " changeset-highlighted"
    };
  }
});

OSM.HistoryChangesetsLayer = L.FeatureGroup.extend({
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

        for (const layer of this._bboxLayers) {
          layer.updateChangesetLayerBounds(changeset);
        }
      }
    }
  },

  reorderChangesets: function () {
    const changesetEntries = [...this._changesets];
    changesetEntries.sort(([, a], [, b]) => b.bounds.getSize() - a.bounds.getSize());
    this._changesets = new Map(changesetEntries);

    for (const layer of this._bboxLayers) {
      layer.clearLayers();
    }

    for (const changeset of this._changesets.values()) {
      if (changeset.sidebarRelativePosition !== 0) {
        this._areaLayer.addChangesetLayer(changeset);
      }
    }

    for (const changeset of this._changesets.values()) {
      if (changeset.sidebarRelativePosition === 0) {
        this._areaLayer.addChangesetLayer(changeset);
      }
    }

    for (const changeset of this._changesets.values()) {
      if (changeset.sidebarRelativePosition !== 0) {
        this._borderLayer.addChangesetLayer(changeset);
      }
    }

    for (const changeset of this._changesets.values()) {
      if (changeset.sidebarRelativePosition === 0) {
        this._outlineLayer.addChangesetLayer(changeset);
      }
    }

    for (const changeset of this._changesets.values()) {
      if (changeset.sidebarRelativePosition === 0) {
        this._borderLayer.addChangesetLayer(changeset);
      }
    }
  },

  toggleChangesetHighlight: function (id, state) {
    const changeset = this._changesets.get(id);
    if (!changeset) return;

    if (state) {
      this._highlightLayer.addChangesetLayer(changeset);
    } else {
      this._highlightLayer.removeLayer(id);
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

  this._bboxLayers = [
    this._areaLayer = new OSM.HistoryChangesetBboxAreaLayer().addTo(this),
    this._outlineLayer = new OSM.HistoryChangesetBboxOutlineLayer().addTo(this),
    this._borderLayer = new OSM.HistoryChangesetBboxBorderLayer().addTo(this),
    this._highlightLayer = new OSM.HistoryChangesetBboxHighlightLayer().addTo(this)
  ];
});
