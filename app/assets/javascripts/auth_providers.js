//= require qs/dist/qs

$(document).ready(function () {
  // Attach referer to authentication buttons
  $(".auth_button").each(function () {
    var params = Qs.parse(this.search.substring(1));
    params.referer = $("#referer").val();
    this.search = Qs.stringify(params);
  });
});
