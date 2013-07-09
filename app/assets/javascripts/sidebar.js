function openSidebar() {
  $("#sidebar-main")
    .hide();

  $("#sidebar")
    .trigger("closed")
    .show()
    .trigger("opened");
}

function closeSidebar() {
  $("#sidebar")
    .hide()
    .trigger("closed");

  $("#sidebar-main")
    .show();
}

$(document).ready(function () {
  $(".sidebar_close").click(function (e) {
    closeSidebar();
    e.preventDefault();
  });
});
