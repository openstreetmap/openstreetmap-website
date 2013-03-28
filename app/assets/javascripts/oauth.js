//= require sha
//= require ohauth

$.ajaxPrefilter(function(options, jqxhr) {
  if (options.oauth) {
    var ohauth = window.ohauth;
    var url = options.url.replace(/\?$/, "");
    var params = {
      oauth_consumer_key: OSM.oauth_consumer_key,
      oauth_token: OSM.oauth_token,
      oauth_signature_method: "HMAC-SHA1",
      oauth_timestamp: ohauth.timestamp(),
      oauth_nonce: ohauth.nonce()
    };

    params.oauth_signature = ohauth.signature(
      OSM.oauth_consumer_secret,
      OSM.oauth_token_secret,
      ohauth.baseString(options.type, url, $.extend({}, params, jqxhr.data))
    );

    options.headers = options.headers || {};
    options.headers.Authorization = "OAuth " + ohauth.authHeader(params);
  }
});
