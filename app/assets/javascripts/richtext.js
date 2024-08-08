$(document).ready(function () {
  /*
   * When the text in an edit pane is changed, clear the contents of
   * the associated preview pne so that it will be regenerated when
   * the user next switches to it.
   */
  $(".richtext_container textarea").change(function () {
    var container = $(this).closest(".richtext_container");

    container.find(".tab-pane[id$='_preview']").empty();
  });

  /*
   * Install a handler to switch to preview mode
   */
  $(".richtext_container button[data-bs-target$='_preview']").on("show.bs.tab", function () {
    var container = $(this).closest(".richtext_container");
    var editor = container.find("textarea");
    var preview = container.find(".tab-pane[id$='_preview']");
    var minHeight = editor.outerHeight() - preview.outerHeight() + preview.height();

    if (preview.contents().length === 0) {
      preview.oneTime(500, "loading", function () {
        preview.addClass("loading");
      });

      preview.load(editor.data("previewUrl"), { text: editor.val() }, function () {
        preview.stopTime("loading");
        preview.removeClass("loading");
      });
    }

    preview.css("min-height", minHeight + "px");
  });
});
