//= require ohauth

$(document).ready(function () {
  function makeAbsolute(url) {
    var a = document.createElement('a');
    a.href = url;
    return a.href;
  }

  if (OSM.oauth_token) {
    var headerGenerator = window.ohauth.headerGenerator({
      consumer_key: OSM.oauth_consumer_key,
      consumer_secret: OSM.oauth_consumer_secret,
      token: OSM.oauth_token,
      token_secret: OSM.oauth_token_secret
    });

    $.ajaxPrefilter(function(options, jqxhr) {
      if (options.oauth) {
        options.headers = options.headers || {};
        options.headers.Authorization = headerGenerator(options.type, makeAbsolute(options.url), jqxhr.data);
      }
    });
  }
});
