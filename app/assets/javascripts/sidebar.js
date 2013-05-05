function openSidebar(options) {
  options = options || {};

  $("#sidebar").trigger("closed");

  if (options.title) { $("#sidebar_title").html(options.title); }

  $("#sidebar").width(options.width || "30%");
  $("#sidebar").css("display", "block").trigger("opened");
  $('#viewanchor').on('click', handleCloseClick);
}

function closeSidebar() {
  $("#sidebar").css("display", "none").trigger("closed");
  $('#viewanchor').off('click', handleCloseClick);
}

function handleCloseClick(e) {
  closeSidebar();
  e.preventDefault();
}

$(document).ready(function () {
  $(".sidebar_close, #viewanchor").click(handleCloseClick);
});
