function maximiseMap() {
  $("#left").hide();
  $("#top-bar").hide();

  $("#content").css("margin-top", "0px");
  if ($("html").attr("dir") == "ltr") {
    $("#content").css("margin-left", "0px");
  } else {
    $("#content").css("margin-right", "0px");
  }

  handleResize();
}

function minimiseMap() {
  $("#left").show();
  $("#top-bar").show();

  $("#content").css("margin-top", "30px");
  if ($("html").attr("dir") == "ltr") {
    $("#content").css("margin-left", "185px");
  } else {
    $("#content").css("margin-right", "185px");
  }

  handleResize();
}

$(document).ready(function () {
  $(window).resize(handleResize);
  handleResize();

  $("#search_form").submit(function () {
    $("#sidebar_title").html(I18n.t('site.sidebar.search_results'));
    $("#sidebar_content").load($(this).attr("action"), {
      query: $("#query").val()
    }, openSidebar);

    return false;
  });
});
