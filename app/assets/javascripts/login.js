$(document).ready(function() {
  // Preserve location hash in referer
  if (window.location.hash) {
    $("#referer").val($("#referer").val() + window.location.hash);
  }

  // Attach referer to authentication buttons
  $(".auth_button").each(function () {
    var params = querystring.parse(this.search.substring(1));
    params.referer = $("#referer").val();
    this.search = querystring.stringify(params);
  });

  // Add click handler to show OpenID field
  $("#openid_open_url").click(function() {
    $("#openid_url").val("http://");
    $("#login_auth_buttons").hide();
    $("#login_openid_url").show();
    $("#login_openid_submit").show();
  });

  // Hide OpenID field for now
  $("#login_openid_url").hide();
  $("#login_openid_submit").hide();
});
