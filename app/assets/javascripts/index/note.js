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
      if (!map.getBounds().contains(latLng)) moveToNote();
    });
  };

  page.load = function (path, id) {
    initialize(path, id);
    moveToNote();
  };

  function initialize(path, id) {
    content.find("button[name]").on("click", function (e) {
      e.preventDefault();
      var data = $(e.target).data();
      var name = $(e.target).attr("name");
      var ajaxSettings = {
        url: data.url,
        type: data.method,
        oauth: true,
        success: () => {
          OSM.loadSidebarContent(path, () => {
            initialize(path, id);
            moveToNote();
          });
        },
        error: (xhr) => {
          content.find("#comment-error")
            .text(xhr.responseText)
            .prop("hidden", false)
            .get(0).scrollIntoView({ block: "nearest" });
          updateButtons();
        }
      };

      if (name !== "subscribe" && name !== "unsubscribe" && name !== "reopen") {
        ajaxSettings.data = { text: $("textarea").val() };
      }

      content.find("button[name]").prop("disabled", true);
      $.ajax(ajaxSettings);
    });

    content.find("textarea").on("input", function (e) {
      updateButtons(e.target.form);
    });

    content.find("textarea").val("").trigger("input");

    var data = $(".details").data();

    if (data) {
      map.addObject({
        type: "note",
        id: parseInt(id, 10),
        latLng: L.latLng(data.coordinates.split(",")),
        icon: noteIcons[data.status]
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

  function moveToNote() {
    var data = $(".details").data();
    if (!data) return;
    var latLng = L.latLng(data.coordinates.split(","));

    if (!window.location.hash || window.location.hash.match(/^#?c[0-9]+$/)) {
      OSM.router.withoutMoveListener(function () {
        map.setView(latLng, 15, { reset: true });
      });
    }
  }

  page.unload = function () {
    map.removeObject();
  };

  return page;
};
