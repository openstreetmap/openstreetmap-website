OSM.Changeset = function (map) {
  const page = {},
        content = $("#sidebar_content");

  page.pushstate = page.popstate = function (path) {
    OSM.loadSidebarContent(path, function () {
      page.load();
    });
  };

  page.load = function () {
    const changesetData = content.find("[data-changeset]").data("changeset");
    changesetData.type = "changeset";

    const hashParams = OSM.parseHash(window.location.hash);
    initialize();
    map.addObject(changesetData, function (bounds) {
      if (!hashParams.center && bounds.isValid()) {
        OSM.router.withoutMoveListener(function () {
          map.fitBounds(bounds);
        });
      }
    });
  };

  function updateChangeset(method, url, include_data) {
    let data;

    content.find("#comment-error").prop("hidden", true);
    content.find("button[data-method][data-url]").prop("disabled", true);

    if (include_data) {
      data = { text: content.find("textarea").val() };
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
        content.find("button[data-method][data-url]").prop("disabled", false);
        content.find("#comment-error")
          .text(xhr.responseText)
          .prop("hidden", false)
          .get(0).scrollIntoView({ block: "nearest" });
      }
    });
  }

  function initialize() {
    content.find("button[data-method][data-url]").on("click", function (e) {
      e.preventDefault();
      const data = $(e.target).data();
      const include_data = e.target.name === "comment";
      updateChangeset(data.method, data.url, include_data);
    });

    content.find("textarea").on("input", function (e) {
      const form = e.target.form,
            disabled = $(e.target).val() === "";
      form.comment.disabled = disabled;
    });

    content.find("textarea").val("").trigger("input");
  }

  page.unload = function () {
    map.removeObject();
  };

  return page;
};
