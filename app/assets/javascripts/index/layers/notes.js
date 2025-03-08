OSM.initializeNotesLayer = function (map) {
  let noteLoader;
  const noteLayer = map.noteLayer;
  let notes = {};

  const noteIcons = {
    "new": L.icon({
      iconUrl: OSM.NEW_NOTE_MARKER,
      iconSize: [25, 40],
      iconAnchor: [12, 40]
    }),
    "open": L.icon({
      iconUrl: OSM.OPEN_NOTE_MARKER,
      iconSize: [25, 40],
      iconAnchor: [12, 40]
    }),
    "closed": L.icon({
      iconUrl: OSM.CLOSED_NOTE_MARKER,
      iconSize: [25, 40],
      iconAnchor: [12, 40]
    })
  };

  noteLayer.on("add", () => {
    loadNotes();
    map.on("moveend", loadNotes);
    map.fire("overlayadd", { layer: noteLayer });
  }).on("remove", () => {
    if (noteLoader) noteLoader.abort();
    noteLoader = null;
    map.off("moveend", loadNotes);
    noteLayer.clearLayers();
    notes = {};
    map.fire("overlayremove", { layer: noteLayer });
  }).on("click", function (e) {
    if (e.layer.id) {
      OSM.router.route("/note/" + e.layer.id);
    }
  });

  function updateMarker(old_marker, feature) {
    let marker = old_marker;
    if (marker) {
      marker.setIcon(noteIcons[feature.properties.status]);
    } else {
      let title;
      const description = feature.properties.comments[0];

      if (description?.action === "opened") {
        title = description.text;
      }

      marker = L.marker(feature.geometry.coordinates.reverse(), {
        icon: noteIcons[feature.properties.status],
        title,
        opacity: 0.8,
        interactive: true
      });
      marker.id = feature.properties.id;
      marker.addTo(noteLayer);
    }
    return marker;
  }

  noteLayer.getLayerId = function (marker) {
    return marker.id;
  };

  function loadNotes() {
    const bounds = map.getBounds();
    const size = bounds.getSize();

    if (size <= OSM.MAX_NOTE_REQUEST_AREA) {
      const url = "/api/" + OSM.API_VERSION + "/notes.json?bbox=" + bounds.toBBoxString();

      if (noteLoader) noteLoader.abort();

      noteLoader = new AbortController();
      fetch(url, { signal: noteLoader.signal })
        .then(response => response.json())
        .then(success)
        .catch(() => {})
        .finally(() => noteLoader = null);
    }

    function success(json) {
      const oldNotes = notes;
      notes = {};
      for (const feature of json.features) {
        const marker = oldNotes[feature.properties.id];
        delete oldNotes[feature.properties.id];
        notes[feature.properties.id] = updateMarker(marker, feature);
      }

      for (const id in oldNotes) {
        noteLayer.removeLayer(oldNotes[id]);
      }
    }
  }
};
