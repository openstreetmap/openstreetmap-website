function openSidebar(options) {
  options = options || {};

  $("#sidebar").trigger("closed");

  if (options.title) { $("#sidebar_title").html(options.title); }

  $("#sidebar").width(options.width || "30%");
  $("#sidebar").css("display", "block").trigger("opened");
}

function closeSidebar() {
  $("#sidebar").css("display", "none").trigger("closed");
}

$(document).ready(function () {
  $(".sidebar_close").click(function (e) {
    closeSidebar();
    e.preventDefault();
  });
});
