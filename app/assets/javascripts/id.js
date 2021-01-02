//= require iD

/* globals iD */

document.addEventListener("DOMContentLoaded", function () {
  var container = document.getElementById("id-container");

  if (typeof iD === "undefined" || !iD.utilDetect().support) {
    container.innerHTML = "This editor is supported " +
      "in Firefox, Chrome, Safari, Opera, Edge, and Internet Explorer 11. " +
      "Please upgrade your browser or use Potlatch 2 to edit the map.";
    container.className = "unsupported";
  } else {
    console.log(parent.location.hash)

    var id = iD.coreContext()
      .embed(true)
      .assetPath("iD/")
      .assetMap(JSON.parse(container.dataset.assetMap))
      .locale(container.dataset.locale)
      .preauth({
        urlroot: location.protocol + "//" + location.host,
        oauth_consumer_key: container.dataset.consumerKey,
        oauth_secret: container.dataset.consumerSecret,
        oauth_token: container.dataset.token,
        oauth_token_secret: container.dataset.tokenSecret
      })
      .containerNode(container)
      .init();

    id.map().on("move.embed", parent.$.throttle(250, function () {
      if (id.inIntro()) return;
      var zoom = ~~id.map().zoom(),
        center = id.map().center(),
        hashParams = parent.OSM.params(location.hash.substring(1)),
        llz = { lon: center[0], lat: center[1], zoom: zoom };

      console.log('location.hash', location.hash)
      console.log('parent.location.hash', parent.location.hash)
      console.log('hashParams', parent.OSM.params(parent.location.hash.substring(1)))
      console.log('mapParams', parent.OSM.mapParams())

      parent.updateLinks(llz, zoom);

      // Manually resolve URL to avoid iframe JS context weirdness.
      // http://bl.ocks.org/jfirebaugh/5439412
      var hash = parent.OSM.formatHash(llz);

      if (hashParams.background) hash += '&background=' + hashParams.background;
      if (hashParams.comment) hash += '&comment=' + hashParams.comment;
      if (hashParams.disable_features) hash += '&disable_features=' + hashParams.disable_features;
      if (hashParams.hashtags) hash += '&hashtags=' + hashParams.hashtags;
      if (hashParams.locale) hash += '&locale=' + hashParams.locale;
      if (hashParams.maprules) hash += '&maprules=' + hashParams.maprules;
      if (hashParams.offset) hash += '&offset=' + hashParams.offset;
      if (hashParams.offset) hash += '&offset=' + hashParams.offset;
      if (hashParams.photo) hash += '&photo=' + hashParams.photo;
      if (hashParams.photo_dates) hash += '&photo_dates=' + hashParams.photo_dates;
      if (hashParams.photo_overlay) hash += '&photo_overlay=' + hashParams.photo_overlay;
      if (hashParams.photo_username) hash += '&photo_username=' + hashParams.photo_username;
      if (hashParams.presets) hash += '&presets=' + hashParams.presets;
      if (hashParams.source) hash += '&source=' + hashParams.source;
      if (hashParams.walkthrough) hash += '&walkthrough=' + hashParams.walkthrough;

      if (hash !== parent.location.hash) {
        parent.location.replace(parent.location.href.replace(/(#.*|$)/, hash));
        console.log(parent.location);
        console.log(hash);
      }
    }));

    parent.$("body").on("click", "a.set_position", function (e) {
      e.preventDefault();
      var data = parent.$(this).data();

      // 0ms timeout to avoid iframe JS context weirdness.
      // http://bl.ocks.org/jfirebaugh/5439412
      setTimeout(function () {
        id.map().centerZoom(
          [data.lon, data.lat],
          Math.max(data.zoom || 15, 13));
      }, 0);
    });
  }
});
