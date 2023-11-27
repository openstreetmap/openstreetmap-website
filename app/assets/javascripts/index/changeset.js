OSM.Changeset = function (map) {
  var page = {},
      content = $("#sidebar_content"),
      currentChangesetId;

  page.pushstate = page.popstate = function (path, id) {
    OSM.loadSidebarContent(path, function () {
      page.load(path, id);
    });
  };

  page.load = function (path, id) {
    if (id) currentChangesetId = id;
    initialize();
    addChangeset(currentChangesetId, true);
  };

  function addChangeset(id, center) {
    map.addObject({ type: "changeset", id: parseInt(id, 10) }, function (bounds) {
      if (!window.location.hash && bounds.isValid() &&
          (center || !map.getBounds().contains(bounds))) {
        OSM.router.withoutMoveListener(function () {
          map.fitBounds(bounds);
        });
      }
    });
  }

  function updateChangeset(form, method, url, include_data) {
    var data;

    $(form).find("#comment-error").prop("hidden", true);
    $(form).find("input[type=submit]").prop("disabled", true);

    if (include_data) {
      data = { text: $(form.text).val() };
    } else {
      data = {};
    }

    $.ajax({
      url: url,
      type: method,
      oauth: true,
      data: data,
      success: function () {
        OSM.loadSidebarContent(window.location.pathname, page.load);
      },
      error: function (xhr) {
        $(form).find("#comment-error").text(xhr.responseText);
        $(form).find("#comment-error").prop("hidden", false);
        $(form).find("input[type=submit]").prop("disabled", false);
      }
    });
  }

  function initialize() {
    content.find("input[name=comment]").on("click", function (e) {
      e.preventDefault();
      var data = $(e.target).data();
      updateChangeset(e.target.form, data.method, data.url, true);
    });

    content.find(".action-button").on("click", function (e) {
      e.preventDefault();
      var data = $(e.target).data();
      updateChangeset(e.target.form, data.method, data.url);
    });

    content.find("textarea").on("input", function (e) {
      var form = e.target.form;

      if ($(e.target).val() === "") {
        $(form.comment).prop("disabled", true);
      } else {
        $(form.comment).prop("disabled", false);
      }
    });

    content.find("textarea").val("").trigger("input");
  }

  page.unload = function () {
    map.removeObject();
  };

  return page;
};
