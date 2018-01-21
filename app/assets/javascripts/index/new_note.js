OSM.NewNote = function(map) {
  var noteLayer = map.noteLayer,
    content = $('#sidebar_content'),
    page = {},
    addNoteButton = $(".control-note .control-button"),
    newNote,
    halo;

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

  addNoteButton.on("click", function (e) {
    e.preventDefault();
    e.stopPropagation();

    if ($(this).hasClass('disabled')) return;

    OSM.router.route('/note/new');
  });

  function createNote(marker, form, url) {
    var location = marker.getLatLng().wrap();

    marker.options.draggable = false;
    marker.dragging.disable();

    $(form).find("input[type=submit]").prop("disabled", true);

    $.ajax({
      url: url,
      type: "POST",
      oauth: true,
      data: {
        lat: location.lat,
        lon: location.lng,
        text: $(form.text).val()
      },
      success: function (feature) {
        noteCreated(feature, marker);
      }
    });

    function noteCreated(feature, marker) {
      content.find("textarea").val("");
      updateMarker(feature);
      newNote = null;
      noteLayer.removeLayer(marker);
      addNoteButton.removeClass("active");
      OSM.router.route('/note/' + feature.properties.id);
    }
  }

  function updateMarker(feature) {
    var marker = L.marker(feature.geometry.coordinates.reverse(), {
      icon: noteIcons[feature.properties.status],
      opacity: 0.9,
      interactive: true
    });
    marker.id = feature.properties.id;
    marker.addTo(noteLayer);
    return marker;
  }

  page.pushstate = page.popstate = function (path) {
    OSM.loadSidebarContent(path, function () {
      page.load(path);
    });
  };

  function newHalo(loc, a) {
    if (a === 'dragstart' && map.hasLayer(halo)) {
      map.removeLayer(halo);
    } else {
      if (map.hasLayer(halo)) map.removeLayer(halo);

      halo = L.circleMarker(loc, {
        weight: 2.5,
        radius: 20,
        fillOpacity: 0.5,
        color: "#FF6200"
      });

      map.addLayer(halo);
    }
  }

  page.load = function (path) {
    if (addNoteButton.hasClass("disabled")) return;
    if (addNoteButton.hasClass("active")) return;

    addNoteButton.addClass("active");

    map.addLayer(noteLayer);

    var params = querystring.parse(path.substring(path.indexOf('?') + 1));
    var markerLatlng;

    if (params.lat && params.lon) {
      markerLatlng = L.latLng(params.lat, params.lon);

      var markerPosition = map.latLngToContainerPoint(markerLatlng),
          mapSize = map.getSize(),
          panBy = L.point(0, 0);

      if (markerPosition.x < 50) {
        panBy.x = markerPosition.x - 50;
      } else if (markerPosition.x > mapSize.x - 50) {
        panBy.x = 50 - mapSize.x + markerPosition.x;
      }

      if (markerPosition.y < 50) {
        panBy.y = markerPosition.y - 50;
      } else if (markerPosition.y > mapSize.y - 50) {
        panBy.y = 50 - mapSize.y + markerPosition.y;
      }

      map.panBy(panBy);
    } else {
      markerLatlng = map.getCenter();
    }

    newNote = L.marker(markerLatlng, {
      icon: noteIcons["new"],
      opacity: 0.9,
      draggable: true
    });

    newNote.on("dragstart dragend", function(a) {
      newHalo(newNote.getLatLng(), a.type);
    });

    newNote.addTo(noteLayer);
    newHalo(newNote.getLatLng());

    newNote.on("remove", function () {
      addNoteButton.removeClass("active");
    }).on("dragstart",function () {
      $(newNote).stopTime("removenote");
    }).on("dragend", function () {
      content.find("textarea").focus();
    });

    content.find("textarea")
      .on("input", disableWhenBlank)
      .focus();

    function disableWhenBlank(e) {
      $(e.target.form.add).prop("disabled", $(e.target).val() === "");
    }

    content.find('input[type=submit]').on('click', function (e) {
      e.preventDefault();
      createNote(newNote, e.target.form, '/api/0.6/notes.json');
    });

    return map.getState();
  };

  page.unload = function () {
    noteLayer.removeLayer(newNote);
    map.removeLayer(halo);
    addNoteButton.removeClass("active");
  };

  return page;
};
