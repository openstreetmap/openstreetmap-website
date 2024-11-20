(function () {
  /*
   * When the text in an edit pane is changed, clear the contents of
   * the associated preview pne so that it will be regenerated when
   * the user next switches to it.
   */
  $(document).on("change", ".richtext_container textarea", function () {
    var container = $(this).closest(".richtext_container");
    var preview = container.find(".tab-pane[id$='_preview']");

    preview.children(".richtext_placeholder").attr("hidden", true).removeClass("delayed-fade-in");
    preview.children(".richtext").empty();
  });

  /*
   * Install a handler to set the minimum preview pane height
   * when switching away from an edit pane
   */
  $(document).on("hide.bs.tab", ".richtext_container button[data-bs-target$='_edit']", function () {
    var container = $(this).closest(".richtext_container");
    var editor = container.find("textarea");
    var preview = container.find(".tab-pane[id$='_preview']");
    var minHeight = editor.outerHeight() - preview.outerHeight() + preview.height();

    preview.css("min-height", minHeight + "px");
  });

  /*
   * Install a handler to switch to preview mode
   */
  $(document).on("show.bs.tab", ".richtext_container button[data-bs-target$='_preview']", function () {
    var container = $(this).closest(".richtext_container");
    var editor = container.find("textarea");
    var preview = container.find(".tab-pane[id$='_preview']");

    if (preview.children(".richtext").contents().length === 0) {
      preview.children(".richtext_placeholder").removeAttr("hidden").addClass("delayed-fade-in");

      preview.children(".richtext").load(editor.data("previewUrl"), { text: editor.val() }, function () {
        preview.children(".richtext_placeholder").attr("hidden", true).removeClass("delayed-fade-in");
      });
    }
  });

  $(window).on("resize", updateHelp);

  $(document).on("turbo:load", function () {
    $(".richtext_container textarea").on("invalid", invalidTextareaListener);
    updateHelp();
  });

  function invalidTextareaListener() {
    var container = $(this).closest(".richtext_container");

    container.find("button[data-bs-target$='_edit']").tab("show");
  }

  function updateHelp() {
    $(".richtext_container .richtext_help_sidebar:not(:visible):not(:empty)").each(function () {
      var container = $(this).closest(".richtext_container");
      $(this).children().appendTo(container.find(".tab-pane[id$='_help']"));
    });
    $(".richtext_container .richtext_help_sidebar:visible:empty").each(function () {
      var container = $(this).closest(".richtext_container");
      container.find(".tab-pane[id$='_help']").children().appendTo($(this));
      if (container.find("button[data-bs-target$='_help'].active").length) {
        container.find("button[data-bs-target$='_edit']").tab("show");
      }
    });
  }
}());
