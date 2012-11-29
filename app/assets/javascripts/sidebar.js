function openSidebar(options) {
  options = options || {};

  $("#sidebar").trigger("closed");

  if (options.title) { $("#sidebar_title").html(options.title); }

  if (options.width) { $("#sidebar").width(options.width); }
  else { $("#sidebar").width("30%"); }

  $("#sidebar").css("display", "block");

  $("#sidebar").trigger("opened");
};

function closeSidebar() {
  $("#sidebar").css("display", "none");

  $("#sidebar").trigger("closed");
}

$(document).ready(function () {
  $(".sidebar_close").click(function (e) {
    closeSidebar();
    e.preventDefault();
  });
});
