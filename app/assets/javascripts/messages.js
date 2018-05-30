$(document).ready(function () {
  $(".inbox-mark-unread").on("ajax:success", function (event, data) {
    $("#inboxanchor").remove();
    $(".user-button").before(data.inboxanchor);

    $("#inbox-count").replaceWith(data.inbox_count);

    $(this).parents(".inbox-row").removeClass("inbox-row").addClass("inbox-row-unread");
  });

  $(".inbox-mark-read").on("ajax:success", function (event, data) {
    $("#inboxanchor").remove();
    $(".user-button").before(data.inboxanchor);

    $("#inbox-count").replaceWith(data.inbox_count);

    $(this).parents(".inbox-row-unread").removeClass("inbox-row-unread").addClass("inbox-row");
  });

  $(".inbox-destroy").on("ajax:success", function (event, data) {
    $("#inboxanchor").remove();
    $(".user-button").before(data.inboxanchor);

    $("#inbox-count").replaceWith(data.inbox_count);

    $(this).parents(".inbox-row, .inbox-row-unread").fadeOut(800, "linear", function () {
      $(this).remove();
    });
  });
});
