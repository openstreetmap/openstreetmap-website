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

    const hashParams = OSM.parseHash();
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
    const data = new URLSearchParams();

    content.find("#comment-error").prop("hidden", true);
    content.find("button[data-method][data-url]").prop("disabled", true);

    if (include_data) {
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
        OSM.loadSidebarContent(location.pathname, page.load);
      })
      .catch(error => {
        content.find("button[data-method][data-url]").prop("disabled", false);
        content.find("#comment-error")
          .text(error.message)
          .prop("hidden", false)
          .get(0).scrollIntoView({ block: "nearest" });
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
