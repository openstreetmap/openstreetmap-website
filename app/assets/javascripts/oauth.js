//= require ohauth

$(document).ready(function () {
  var application_data = $("head").data();

  function makeAbsolute(url) {
    var a = document.createElement("a");
    a.href = url;
    return a.href;
  }

  if (application_data.token) {
    var headerGenerator = window.ohauth.headerGenerator({
      consumer_key: application_data.consumerKey,
      consumer_secret: application_data.consumerSecret,
      token: application_data.token,
      token_secret: application_data.tokenSecret
    });

    $.ajaxPrefilter(function(options, jqxhr) {
      if (options.oauth) {
        options.headers = options.headers || {};
        options.headers.Authorization = headerGenerator(options.type, makeAbsolute(options.url), jqxhr.data);
      }
    });
  }
});
