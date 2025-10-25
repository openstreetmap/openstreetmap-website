OSM.HistoryChangesetBboxLayer = L.FeatureGroup.extend({
  getLayerId: function (layer) {
    return layer.id;
  },

  addChangesetLayer: function (changeset) {
    const style = this._getChangesetStyle(changeset);
    const rectangle = L.rectangle(changeset.bounds, { ...style });
    rectangle.on("contextmenu", (e) => {
      L.DomEvent.stopPropagation(e); // Prevent map context menu
      const contextmenuItems = [{
        icon: "bi-arrow-down-up",
        text: OSM.i18n.t("javascripts.context.scroll_to_changeset"),
        callback: () => this.fire("requestscrolltochangeset", { id: changeset.id }, true)
      }];
      this._map.fire("show-contextmenu", { event: e, items: contextmenuItems });
    });

    rectangle.id = changeset.id;
    rectangle.on("click", function (e) {
      OSM.router.click(e.originalEvent, $(`#changeset_${changeset.id} a.changeset_id`).attr("href"));
    });
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
      stroke: false,
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

OSM.HistoryChangesetBboxHighlightAreaLayer = OSM.HistoryChangesetBboxLayer.extend({
  _getChangesetStyle: function (changeset) {
    return {
      interactive: false,
      stroke: false,
      fillColor: "var(--changeset-fill-color)",
      fillOpacity: 0.3,
      className: this._getSidebarRelativeClassName(changeset)
    };
  }
});

OSM.HistoryChangesetBboxHighlightOutlineLayer = OSM.HistoryChangesetBboxLayer.extend({
  _getChangesetStyle: function (changeset) {
    return {
      interactive: false,
      weight: changeset.sidebarRelativePosition === 0 ? 8 : 6,
      color: "var(--changeset-outline-color)",
      fill: false,
      className: this._getSidebarRelativeClassName(changeset) + " changeset-highlight-outline"
    };
  }
});

OSM.HistoryChangesetBboxHighlightBorderLayer = OSM.HistoryChangesetBboxLayer.extend({
  _getChangesetStyle: function (changeset) {
    return {
      interactive: false,
      weight: 4,
      color: "var(--changeset-border-color)",
      fill: false,
      className: this._getSidebarRelativeClassName(changeset)
    };
  }
});

OSM.HistoryChangesetsLayer = L.FeatureGroup.extend({
  updateChangesets: function (map, changesets) {
    this._changesets = new Map(changesets.map(changeset => [changeset.id, changeset]));
    this.updateChangesetsGeometry(map);
  },

  updateChangesetsGeometry: function (map) {
    const changesetSizeLowerBound = 20, // Min width/height of changeset in pixels
          mapViewExpansion = 2; // Half of bbox border+outline width in pixels

    const mapViewCenterLng = map.getCenter().lng,
          mapViewPixelBounds = map.getPixelBounds();

    mapViewPixelBounds.min.x -= mapViewExpansion;
    mapViewPixelBounds.min.y -= mapViewExpansion;
    mapViewPixelBounds.max.x += mapViewExpansion;
    mapViewPixelBounds.max.y += mapViewExpansion;

    for (const changeset of this._changesets.values()) {
      const changesetNorthWestLatLng = L.latLng(changeset.bbox.maxlat, changeset.bbox.minlon),
            changesetSouthEastLatLng = L.latLng(changeset.bbox.minlat, changeset.bbox.maxlon),
            changesetCenterLng = (changesetNorthWestLatLng.lng + changesetSouthEastLatLng.lng) / 2,
            shiftInWorldCircumferences = Math.round((changesetCenterLng - mapViewCenterLng) / 360);

      if (shiftInWorldCircumferences) {
        changesetNorthWestLatLng.lng -= shiftInWorldCircumferences * 360;
        changesetSouthEastLatLng.lng -= shiftInWorldCircumferences * 360;
      }

      const changesetMinCorner = map.project(changesetNorthWestLatLng),
            changesetMaxCorner = map.project(changesetSouthEastLatLng),
            changesetSizeX = changesetMaxCorner.x - changesetMinCorner.x,
            changesetSizeY = changesetMaxCorner.y - changesetMinCorner.y;

      if (changesetSizeX < changesetSizeLowerBound) {
        changesetMinCorner.x -= (changesetSizeLowerBound - changesetSizeX) / 2;
        changesetMaxCorner.x += (changesetSizeLowerBound - changesetSizeX) / 2;
      }

      if (changesetSizeY < changesetSizeLowerBound) {
        changesetMinCorner.y -= (changesetSizeLowerBound - changesetSizeY) / 2;
        changesetMaxCorner.y += (changesetSizeLowerBound - changesetSizeY) / 2;
      }

      changeset.bounds = L.latLngBounds(map.unproject(changesetMinCorner),
                                        map.unproject(changesetMaxCorner));

      const changesetPixelBounds = L.bounds(changesetMinCorner, changesetMaxCorner);

      changeset.hasEdgesInMapView = changesetPixelBounds.overlaps(mapViewPixelBounds) &&
                                    !changesetPixelBounds.contains(mapViewPixelBounds);
    }

    this.updateChangesetsOrder();
  },

  updateChangesetsOrder: function () {
    const changesetEntries = [...this._changesets];
    changesetEntries.sort(([, a], [, b]) => b.bounds.getSize() - a.bounds.getSize());
    this._changesets = new Map(changesetEntries);

    for (const layer of this._bboxLayers) {
      layer.clearLayers();
    }

    for (const changeset of this._changesets.values()) {
      if (changeset.sidebarRelativePosition !== 0 && changeset.hasEdgesInMapView) {
        this._areaLayer.addChangesetLayer(changeset);
      }
    }

    for (const changeset of this._changesets.values()) {
      if (changeset.sidebarRelativePosition === 0 && changeset.hasEdgesInMapView) {
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

    this._highlightAreaLayer.clearLayers();
    this._highlightOutlineLayer.clearLayers();
    this._highlightBorderLayer.clearLayers();

    if (state) {
      this._highlightAreaLayer.addChangesetLayer(changeset);
      this._highlightOutlineLayer.addChangesetLayer(changeset);
      this._highlightBorderLayer.addChangesetLayer(changeset);
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
    this._highlightAreaLayer = new OSM.HistoryChangesetBboxHighlightAreaLayer().addTo(this),
    this._highlightOutlineLayer = new OSM.HistoryChangesetBboxHighlightOutlineLayer().addTo(this),
    this._highlightBorderLayer = new OSM.HistoryChangesetBboxHighlightBorderLayer().addTo(this)
  ];
});
