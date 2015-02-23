$(document).ready(function () {
  /* Hide the preview panes */
  $(".richtext_preview").hide();

  /* 
   * When the text in an edit pane is changed, clear the contents of
   * the associated preview pne so that it will be regenerated when
   * the user next switches to it.
   */
  $(".richtext_content textarea").change(function () { 
    $(this).parents(".richtext_container").find(".richtext_preview").empty();
  });

  /* Disable all the edit buttons */
  $(".richtext_doedit").prop("disabled", true);

  /* Enable the preview buttons */
  $(".richtext_dopreview").prop("disabled", false);

  /*
   * Install a click handler to switch to edit mode when the
   * edit button is pressed.
   */
  $(".richtext_doedit").click(function (event) {
    var editor = $(this).parents(".richtext_container").find("textarea");
    var preview = $(this).parents(".richtext_container").find(".richtext_preview");

    preview.hide();
    editor.show();

    $(this).siblings(".richtext_dopreview").prop("disabled", false);
    $(this).prop("disabled", true);

    event.preventDefault();
  });

  /*
   * Install a click handler to switch to preview mode when the
   * preview button is pressed.
   */
  $(".richtext_dopreview").click(function (event) {
    var editor = $(this).parents(".richtext_container").find("textarea");
    var preview = $(this).parents(".richtext_container").find(".richtext_preview");
    var width = editor.outerWidth() - preview.outerWidth() + preview.width();
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

    editor.hide();
    preview.width(width);
    preview.css("min-height", minHeight + "px");
    preview.show();

    $(this).siblings(".richtext_doedit").prop("disabled", false);
    $(this).prop("disabled", true);

    event.preventDefault();
  });
});
