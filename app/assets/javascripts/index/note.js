OSM.Note = function (map) {
  var content = $("#sidebar_content"),
      page = {};

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

  page.pushstate = page.popstate = function (path, id) {
    OSM.loadSidebarContent(path, function () {
      initialize(path, id);

      var data = $(".details").data();
      if (!data) return;
      var latLng = L.latLng(data.coordinates.split(","));
      if (!map.getBounds().contains(latLng)) {
        OSM.router.withoutMoveListener(function () {
          map.setView(latLng, 15, { reset: true });
        });
      }
    });
  };

  page.load = function (path, id) {
    initialize(path, id);
  };

  function initialize(path, id) {
    content.find("button[name]").on("click", function (e) {
      e.preventDefault();
      const { url, method } = $(e.target).data(),
            name = $(e.target).attr("name"),
            data = new URLSearchParams();
      content.find("button[name]").prop("disabled", true);

      if (name !== "subscribe" && name !== "unsubscribe" && name !== "reopen") {
        data.set("text", content.find("textarea").val());
      }

      fetch(url, {
        method: method,
        headers: { ...OSM.oauth },
        body: data
      })
        .then(response => {
          if (response.ok) return response;
          return response.text().then(text => {
            throw new Error(text);
          });
        })
        .then(() => {
          OSM.loadSidebarContent(path, () => {
            initialize(path, id);
          });
        })
        .catch(error => {
          content.find("#comment-error")
            .text(error.message)
            .prop("hidden", false)
            .get(0).scrollIntoView({ block: "nearest" });
          updateButtons();
        });
    });

    content.find("textarea").on("input", function (e) {
      updateButtons(e.target.form);
    });

    content.find("textarea").val("").trigger("input");

    var data = $(".details").data();

    if (data) {
      var hashParams = OSM.parseHash(window.location.hash);
      map.addObject({
        type: "note",
        id: parseInt(id, 10),
        latLng: L.latLng(data.coordinates.split(",")),
        icon: noteIcons[data.status]
      }, function () {
        if (!hashParams.center) {
          var latLng = L.latLng(data.coordinates.split(","));
          OSM.router.withoutMoveListener(function () {
            map.setView(latLng, 15, { reset: true });
          });
        }
      });
    }
  }

  function updateButtons() {
    var resolveButton = content.find("button[name='close']");
    var commentButton = content.find("button[name='comment']");

    content.find("button[name]").prop("disabled", false);
    if (content.find("textarea").val() === "") {
      resolveButton.text(resolveButton.data("defaultActionText"));
      commentButton.prop("disabled", true);
    } else {
      resolveButton.text(resolveButton.data("commentActionText"));
    }
  }

  page.unload = function () {
    map.removeObject();
  };

  return page;
};
