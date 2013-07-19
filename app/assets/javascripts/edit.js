function maximiseMap() {
  $("#content").addClass("maximised");
}

function minimiseMap() {
  $("#content").removeClass("maximised");
}

$(document).ready(function () {
  $("#search_form").submit(function () {
    $("#sidebar_title").html(I18n.t('site.sidebar.search_results'));
    $("#sidebar_content").load($(this).attr("action"), {
      query: $("#query").val()
    }, openSidebar);

    return false;
  });
});
