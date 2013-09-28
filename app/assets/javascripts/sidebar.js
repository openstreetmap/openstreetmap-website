function closeSidebar() {
  $("#sidebar")
    .trigger("closed");
}

$(document).ready(function () {
  $(".sidebar_close").click(function (e) {
    closeSidebar();
    e.preventDefault();
  });
});
