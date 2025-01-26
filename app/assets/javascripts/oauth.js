$(document).ready(function () {
  const application_data = $("head").data();

  if (application_data.oauthToken) {
    $.ajaxPrefilter(function (options) {
      if (options.oauth) {
        options.headers = options.headers || {};
        options.headers.Authorization = "Bearer " + application_data.oauthToken;
      }
    });
  }
});
