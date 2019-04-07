OSM.initializeNotes = function (map) {
  var noteLayer = map.noteLayer,
      notes = {};

  var noteIcons = {
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

  map.on("layeradd", function (e) {
    if (e.layer === noteLayer) {
      loadNotes();
      map.on("moveend", loadNotes);
    }
  }).on("layerremove", function (e) {
    if (e.layer === noteLayer) {
      map.off("moveend", loadNotes);
      noteLayer.clearLayers();
      notes = {};
    }
  });

  noteLayer.on("click", function (e) {
    if (e.layer.id) {
      OSM.router.route("/note/" + e.layer.id);
    }
  });

  function updateMarker(marker, feature) {
    if (marker) {
      marker.setIcon(noteIcons[feature.properties.status]);
    } else {
      marker = L.marker(feature.geometry.coordinates.reverse(), {
        icon: noteIcons[feature.properties.status],
        title: feature.properties.comments[0].text,
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

  var noteLoader;

  function loadNotes() {
    var bounds = map.getBounds();
    var size = bounds.getSize();

    if (size <= OSM.MAX_NOTE_REQUEST_AREA) {
      var url = "/api/" + OSM.API_VERSION + "/notes.json?bbox=" + bounds.toBBoxString();

      if (noteLoader) noteLoader.abort();

      noteLoader = $.ajax({
        url: url,
        success: success
      });
    }

    function success(json) {
      var oldNotes = notes;
      notes = {};
      json.features.forEach(updateMarkers);

      function updateMarkers(feature) {
        var marker = oldNotes[feature.properties.id];
        delete oldNotes[feature.properties.id];
        notes[feature.properties.id] = updateMarker(marker, feature);
      }

      for (var id in oldNotes) {
        noteLayer.removeLayer(oldNotes[id]);
      }

      noteLoader = null;
    }
  }
};
