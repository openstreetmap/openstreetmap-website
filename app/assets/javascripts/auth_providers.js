//= require qs/dist/qs

$(document).ready(function () {
  // Attach referer to authentication buttons
  $(".auth_button").each(function () {
    var params = Qs.parse(this.search.substring(1));
    params.referer = $("#referer").val();
    this.search = Qs.stringify(params);
  });

  // Add click handler to show OpenID field
  $("#openid_open_url").click(function () {
    $("#openid_url").val("http://");
    $("#login_auth_buttons").hide();
    $("#login_openid_url").show();
    $("#openid_login_button").show();
  });

  // Hide OpenID field for now
  $("#login_openid_url").hide();
  $("#openid_login_button").hide();
});
