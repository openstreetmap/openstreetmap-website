//= require qs/dist/qs

OSM.NewNote = function (map) {
  var noteLayer = map.noteLayer,
      content = $("#sidebar_content"),
      page = {},
      addNoteButton = $(".control-note .control-button"),
      newNoteMarker,
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

    if ($(this).hasClass("disabled")) return;

    OSM.router.route("/note/new");
  });

  function createNote(location, text, callback) {
    $.ajax({
      url: "/api/0.6/notes.json",
      type: "POST",
      oauth: true,
      data: {
        lat: location.lat,
        lon: location.lng,
        text
      },
      success: callback
    });
  }

  function addCreatedNoteMarker(feature) {
    var marker = L.marker(feature.geometry.coordinates.reverse(), {
      icon: noteIcons[feature.properties.status],
      opacity: 0.9,
      interactive: true
    });
    marker.id = feature.properties.id;
    marker.addTo(noteLayer);
  }

  function newHalo(loc, a) {
    var hasHalo = halo && map.hasLayer(halo);

    if (a === "dragstart" && hasHalo) {
      map.removeLayer(halo);
    } else {
      if (hasHalo) map.removeLayer(halo);

      halo = L.circleMarker(loc, {
        weight: 2.5,
        radius: 20,
        fillOpacity: 0.5,
        color: "#FF6200"
      });

      map.addLayer(halo);
    }
  }

  page.pushstate = page.popstate = function (path) {
    OSM.loadSidebarContent(path, function () {
      page.load(path);
    });
  };

  page.load = function (path) {
    if (addNoteButton.hasClass("disabled")) return;
    if (addNoteButton.hasClass("active")) return;

    addNoteButton.addClass("active");

    map.addLayer(noteLayer);

    var params = Qs.parse(path.substring(path.indexOf("?") + 1));
    var markerLatlng;

    if (params.lat && params.lon) {
      markerLatlng = L.latLng(params.lat, params.lon);
    } else {
      markerLatlng = map.getCenter();
    }

    map.panInside(markerLatlng, {
      padding: [50, 50]
    });

    newNoteMarker = L.marker(markerLatlng, {
      icon: noteIcons.new,
      opacity: 0.9,
      draggable: true
    });

    newNoteMarker.on("dragstart dragend", function (a) {
      newHalo(newNoteMarker.getLatLng(), a.type);
    });

    newNoteMarker.addTo(map);
    newHalo(newNoteMarker.getLatLng());

    newNoteMarker.on("remove", function () {
      addNoteButton.removeClass("active");
    }).on("dragend", function () {
      content.find("textarea").focus();
    });

    content.find("textarea")
      .on("input", disableWhenBlank)
      .focus();

    function disableWhenBlank(e) {
      $(e.target.form.add).prop("disabled", $(e.target).val() === "");
    }

    content.find("input[type=submit]").on("click", function (e) {
      const location = newNoteMarker.getLatLng().wrap();
      const text = content.find("textarea").val();

      e.preventDefault();
      $(this).prop("disabled", true);
      newNoteMarker.options.draggable = false;
      newNoteMarker.dragging.disable();

      createNote(location, text, (feature) => {
        content.find("textarea").val("");
        addCreatedNoteMarker(feature);
        map.removeLayer(newNoteMarker);
        newNoteMarker = null;
        addNoteButton.removeClass("active");
        OSM.router.route("/note/" + feature.properties.id);
      });
    });

    return map.getState();
  };

  page.unload = function () {
    if (newNoteMarker) map.removeLayer(newNoteMarker);
    if (halo) map.removeLayer(halo);
    addNoteButton.removeClass("active");
  };

  return page;
};
