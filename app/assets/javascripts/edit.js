function maximiseMap() {
  $("#left").hide();
  $("#greeting").hide();
  $("#tabnav").hide();

  $("#content").css("top", "0px");
  if ($("html").attr("dir") == "ltr") {
    $("#content").css("left", "0px");
  } else {
    $("#content").css("right", "0px");
  }

  handleResize();
}

function minimiseMap() {
  $("#left").show();
  $("#greeting").show();
  $("#tabnav").show();

  $("#content").css("top", "30px");
  if ($("html").attr("dir") == "ltr") {
    $("#content").css("left", "185px");
  } else {
    $("#content").css("right", "185px");
  }

  handleResize();
}

$(document).ready(handleResize);
$(window).resize(handleResize);
