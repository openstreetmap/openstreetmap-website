export default function (map) {
  const content = $("#sidebar_content");

  content.on("turbo:before-frame-render", "turbo-frame", function () {
    $(this).find(".numbered_pagination").trigger("numbered_pagination:disable");
  });

  content.on("turbo:frame-render", "turbo-frame", function () {
    $(this).find(".numbered_pagination").trigger("numbered_pagination:enable");
  });

  return {
    load(path) {
      OSM.loadSidebarContent(path)
        .then(this.init);
    },

    init() {
      const changesetData = content.find("[data-changeset]").data("changeset");
      changesetData.type = "changeset";

      const hashParams = OSM.parseHash();
      content.find("button[data-method][data-url]").on("click", function (e) {
        e.preventDefault();
        const { method, url } = $(e.target).data();
        const data = new URLSearchParams();

        content.find("#comment-error").prop("hidden", true);
        content.find("button[data-method][data-url]").prop("disabled", true);

        if (e.target.name === "comment") {
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
          .then(() => OSM.loadSidebarContent(location.pathname))
          .then(this.init)
          .catch(error => {
            content.find("button[data-method][data-url]").prop("disabled", false);
            content.find("#comment-error")
              .text(error.message)
              .prop("hidden", false)
              .get(0).scrollIntoView({ block: "nearest" });
          });
      });

      content.find("textarea").on("input", function (e) {
        const form = e.target.form,
              disabled = $(e.target).val() === "";
        form.comment.disabled = disabled;
      });

      content.find("textarea").val("").trigger("input");
      map.addObject(changesetData, function (bounds) {
        if (!hashParams.center && bounds.isValid()) {
          OSM.router.withoutMoveListener(function () {
            map.fitBounds(bounds);
          });
        }
      });
      $(".numbered_pagination").trigger("numbered_pagination:enable");
    },

    unload() {
      map.removeObject();
      $(".numbered_pagination").trigger("numbered_pagination:disable");
    }
  };
}
