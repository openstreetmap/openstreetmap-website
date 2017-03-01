//= require iD

document.addEventListener("DOMContentLoaded", function(e) {
  var container = document.getElementById("id-container");

  if (typeof iD == 'undefined' || !iD.Detect().support) {
    container.innerHTML = 'This editor is supported ' +
      'in Firefox, Chrome, Safari, Opera, Edge, and Internet Explorer 11. ' +
      'Please upgrade your browser or use Potlatch 2 to edit the map.';
    container.className = 'unsupported';
  } else {
    var id = iD.Context()
      .embed(true)
      .assetPath("iD/")
      .assetMap(container.dataset.assetMap)
      .locale(container.dataset.locale, container.dataset.localePath)
      .preauth({
        urlroot: location.protocol + "//" + location.host,
        oauth_consumer_key: container.dataset.consumerKey,
        oauth_secret: container.dataset.consumerSecret,
        oauth_token: container.dataset.token,
        oauth_token_secret: container.dataset.tokenSecret
      });

    id.map().on('move.embed', parent.$.throttle(250, function() {
      if (id.inIntro()) return;
      var zoom = ~~id.map().zoom(),
        center = id.map().center(),
        llz = { lon: center[0], lat: center[1], zoom: zoom };

      parent.updateLinks(llz, zoom);

      // Manually resolve URL to avoid iframe JS context weirdness.
      // http://bl.ocks.org/jfirebaugh/5439412
      var hash = parent.OSM.formatHash(llz);
      if (hash !== parent.location.hash) {
        parent.location.replace(parent.location.href.replace(/(#.*|$)/, hash));
      }
    }));

    parent.$("body").on("click", "a.set_position", function (e) {
      e.preventDefault();
      var data = parent.$(this).data();

      // 0ms timeout to avoid iframe JS context weirdness.
      // http://bl.ocks.org/jfirebaugh/5439412
      setTimeout(function() {
        id.map().centerZoom(
          [data.lon, data.lat],
          Math.max(data.zoom || 15, 13));
      }, 0);
    });

    id.ui()(container);
  }
});
