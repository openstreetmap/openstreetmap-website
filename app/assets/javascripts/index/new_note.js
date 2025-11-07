OSM.initializations.push(function () {
  $(".control-note .control-button").on("click", function (e) {
    e.preventDefault();
    e.stopPropagation();

    if ($(this).hasClass("disabled")) return;

    OSM.router.route("/note/new");
  });
});

OSM.NewNote = function (map) {
  const noteLayer = map.noteLayer,
        content = $("#sidebar_content"),
        page = {},
        control = $(".control-note"),
        addNoteButton = control.find(".control-button");
  let newNoteMarker,
      halo;

  function createNote(location, text, callback) {
    fetch("/api/0.6/notes.json", {
      method: "POST",
      headers: { ...OSM.oauth },
      body: new URLSearchParams({
        lat: location.lat,
        lon: location.lng,
        text
      })
    })
      .then(response => response.json())
      .then(callback);
  }

  function addCreatedNoteMarker(feature) {
    const marker = L.marker(feature.geometry.coordinates.reverse(), {
      icon: OSM.noteMarkers[feature.properties.status],
      opacity: 0.9,
      interactive: true
    });
    marker.id = feature.properties.id;
    marker.addTo(noteLayer);
  }

  function addHalo(latlng) {
    if (halo) map.removeLayer(halo);

    halo = L.circleMarker(latlng, {
      weight: 2.5,
      radius: 20,
      fillOpacity: 0.5,
      color: "#FF6200"
    });

    map.addLayer(halo);
  }

  function removeHalo() {
    if (halo) map.removeLayer(halo);
    halo = null;
  }

  function addNewNoteMarker(latlng) {
    if (newNoteMarker) map.removeLayer(newNoteMarker);

    newNoteMarker = L.marker(latlng, {
      icon: OSM.noteMarkers.new,
      opacity: 0.9,
      draggable: true
    });

    newNoteMarker.on("dragstart dragend", function (a) {
      removeHalo();
      if (a.type === "dragend") {
        addHalo(newNoteMarker.getLatLng());
      }
    });

    newNoteMarker.addTo(map);
    addHalo(newNoteMarker.getLatLng());

    newNoteMarker.on("dragend", function () {
      content.find("textarea").trigger("focus");
    });
  }

  function removeNewNoteMarker() {
    removeHalo();
    if (newNoteMarker) map.removeLayer(newNoteMarker);
    newNoteMarker = null;
  }

  function moveNewNoteMarkerToClick(e) {
    if (newNoteMarker) newNoteMarker.setLatLng(e.latlng);
    if (halo) halo.setLatLng(e.latlng);
    content.find("textarea").trigger("focus");
  }

  function updateControls() {
    const zoomedOut = addNoteButton.hasClass("disabled");
    const withoutText = content.find("textarea").val() === "";

    content.find("#new-note-zoom-warning").prop("hidden", !zoomedOut);
    content.find("input[type=submit]").prop("disabled", zoomedOut || withoutText);
    if (newNoteMarker) newNoteMarker.setOpacity(zoomedOut ? 0.5 : 0.9);
  }

  page.pushstate = page.popstate = function (path) {
    OSM.loadSidebarContent(path, function () {
      page.load(path);
    });
  };

  page.load = function (path) {
    control.addClass("active");

    map.addLayer(noteLayer);

    const params = new URLSearchParams(path.substring(path.indexOf("?")));
    let markerLatlng;

    if (params.has("lat") && params.has("lon")) {
      markerLatlng = L.latLng(params.get("lat"), params.get("lon"));
    } else {
      markerLatlng = map.getCenter();
    }

    map.panInside(markerLatlng, {
      padding: [50, 50]
    });

    addNewNoteMarker(markerLatlng);

    content.find("textarea")
      .on("input", updateControls)
      .attr("readonly", "readonly") // avoid virtual keyboard popping up on focus
      .trigger("focus")
      .removeAttr("readonly");

    content.find("input[type=submit]").on("click", function (e) {
      const location = newNoteMarker.getLatLng().wrap();
      const text = content.find("textarea").val();

      e.preventDefault();
      $(this).prop("disabled", true);
      newNoteMarker.options.draggable = false;
      newNoteMarker.dragging.disable();

      createNote(location, text, (feature) => {
        if (typeof OSM.user === "undefined") {
          const anonymousNotesCount = Number(OSM.cookies.get("_osm_anonymous_notes_count")) || 0;
          OSM.cookies.set("_osm_anonymous_notes_count", anonymousNotesCount + 1, { expires: 30 });
        }
        content.find("textarea").val("");
        addCreatedNoteMarker(feature);
        OSM.router.route("/note/" + feature.properties.id);
      });
    });

    map.on("click", moveNewNoteMarkerToClick);
    addNoteButton.on("disabled enabled", updateControls);
    updateControls();

    return map.getState();
  };

  page.unload = function () {
    map.off("click", moveNewNoteMarkerToClick);
    addNoteButton.off("disabled enabled", updateControls);
    removeNewNoteMarker();
    control.removeClass("active");
  };

  return page;
};
