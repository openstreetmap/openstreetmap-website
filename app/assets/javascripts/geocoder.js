$(document).ready(function () {
  $("body").on("click", ".search_more a", function (e) {
    e.preventDefault();

    var div = $(this).parents(".search_more");

    div.find(".search_results_entry").hide();
    div.find(".search_searching").show();

    $.get($(this).attr("href"), function(data) {
      div.replaceWith(data);
    });
  });
});
