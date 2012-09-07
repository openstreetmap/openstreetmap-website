function resizeContent() {
  var content = $("#content");
  var leftMargin = parseInt(content.css("left"));
  var rightMargin = parseInt(content.css("right"));
  var bottomMargin = parseInt(content.css("bottom"));

  if ($("html").attr("dir") == "ltr") {
    content.width($(window).width() - content.prop("offsetLeft") - rightMargin);
  } else {
    content.width($(window).width() - content.prop("offsetRight") - leftMargin);
  }

  content.height($(window).height() - content.prop("offsetTop") - bottomMargin);
}

function resizeMap() {
  var content_width = $("#content").width();
  var content_height = $("#content").height();
  var sidebar_width = 0;
  var left_border = parseFloat($("#map").css("border-left-width"));
  var right_border = parseFloat($("#map").css("border-right-width"));
  var top_border = parseFloat($("#map").css("border-top-width"));
  var bottom_border = parseFloat($("#map").css("border-bottom-width"));

  $("#sidebar:visible").each(function () {
    sidebar_width = sidebar_width + $(this).outerWidth(true);
  });

  if ($("html").attr("dir") == "ltr") {
    $("#map").css("left", (sidebar_width) + "px");
  } else {
    $("#map").css("right", (sidebar_width) + "px");
  }

  $("#map").width(content_width - sidebar_width - left_border - right_border);
  $("#map").height(content_height - top_border - bottom_border);
  $("#map").trigger("resized");
}

function handleResize() {
  var brokenContentSize = $("#content").prop("offsetWidth") == 0;

  if (brokenContentSize) {
    resizeContent();
  }

  resizeMap();
}

$(document).ready(function () {
  $("#sidebar").on("opened", resizeMap);
  $("#sidebar").on("closed", resizeMap);
});
