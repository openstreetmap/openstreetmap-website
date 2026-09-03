export default function (map) {
  const page = {},
        content = $("#sidebar_content");
  let lifecycle = 0;

  content.on("turbo:before-frame-render", "turbo-frame", function () {
    $(this).find(".numbered_pagination").trigger("numbered_pagination:disable");
  });

  content.on("turbo:frame-render", "turbo-frame", function () {
    $(this).find(".numbered_pagination").trigger("numbered_pagination:enable");
  });

  page.load = function (path) {
    const currentLifecycle = ++lifecycle;

    OSM.loadSidebarContent(path)
      .then(() => {
        if (lifecycle !== currentLifecycle) return;
        initializePage(path, currentLifecycle);
      });
  };

  page.init = function (path) {
    const currentLifecycle = ++lifecycle;
    initializePage(path, currentLifecycle);
  };

  function initializePage(path, currentLifecycle) {
    const changesetData = content.find("[data-changeset]").data("changeset");
    changesetData.type = "changeset";

    const hashParams = OSM.parseHash();
    initialize(path, currentLifecycle);
    map.addObject(changesetData, function (bounds) {
      if (lifecycle !== currentLifecycle) return;

      if (!hashParams.center && bounds.isValid()) {
        OSM.router.withoutMoveListener(function () {
          map.fitBounds(bounds);
        });
      }
    });
    $(".numbered_pagination").trigger("numbered_pagination:enable");
  }

  function updateChangeset(method, url, include_data, path, currentLifecycle) {
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
      .then(async () => {
        if (lifecycle !== currentLifecycle) return;

        await OSM.loadSidebarContent(path);
        if (lifecycle !== currentLifecycle) return;

        initializePage(path, currentLifecycle);
      })
      .catch(error => {
        if (lifecycle !== currentLifecycle) return;

        content.find("button[data-method][data-url]").prop("disabled", false);
        content.find("#comment-error")
          .text(error.message)
          .prop("hidden", false)
          .get(0).scrollIntoView({ block: "nearest" });
      });
  }

  function initialize(path, currentLifecycle) {
    content.find("button[data-method][data-url]").on("click", function (e) {
      e.preventDefault();
      const data = $(e.target).data();
      const include_data = e.target.name === "comment";
      updateChangeset(data.method, data.url, include_data, path, currentLifecycle);
    });

    content.find("textarea").on("input", function (e) {
      const form = e.target.form,
            disabled = $(e.target).val() === "";
      form.comment.disabled = disabled;
    });

    content.find("textarea").val("").trigger("input");
  }

  page.unload = function () {
    lifecycle++;
    map.removeObject();
    $(".numbered_pagination").trigger("numbered_pagination:disable");
  };

  return page;
}
