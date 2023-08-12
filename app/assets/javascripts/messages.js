$(document).ready(function () {
  $(".inbox-mark-unread").on("ajax:success", function (event, data) {
    updateHtml(data);
    updateReadState(this, false);
  });

  $(".inbox-mark-read").on("ajax:success", function (event, data) {
    updateHtml(data);
    updateReadState(this, true);
  });

  $(".inbox-destroy").on("ajax:success", function (event, data) {
    updateHtml(data);

    $(this).closest("tr").fadeOut(800, "linear", function () {
      $(this).remove();
    });
  });

  function updateHtml(data) {
    $("#inboxanchor").remove();
    $(".user-button").before(data.inboxanchor);

    $("#inbox-count").replaceWith(data.inbox_count);
  }

  function updateReadState(target, isRead) {
    $(target).closest("tr")
      .toggleClass("inbox-row", isRead)
      .toggleClass("inbox-row-unread", !isRead)
      .find(".inbox-mark-unread").prop("hidden", !isRead).end()
      .find(".inbox-mark-read").prop("hidden", isRead);
  }
});
