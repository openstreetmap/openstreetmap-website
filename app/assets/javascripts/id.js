//= require iD

/* globals iD */

document.addEventListener("DOMContentLoaded", function () {
  var container = document.getElementById("id-container");

  if (typeof iD === "undefined" || !iD.utilDetect().support) {
    container.innerHTML = "This editor is supported " +
      "in Firefox, Chrome, Safari, Opera and Edge. " +
      "Please upgrade your browser or use JOSM to edit the map.";
    container.className = "unsupported";
  } else {
    var idContext = iD.coreContext();
    idContext.connection().apiConnections([]);
    idContext.preauth({
      url: location.protocol + "//" + location.host,
      access_token: container.dataset.token
    });

    var id = idContext
      .embed(true)
      .assetPath("iD/")
      .assetMap(JSON.parse(container.dataset.assetMap))
      .locale(container.dataset.locale)
      .containerNode(container)
      .init();

    id.map().on("move.embed", parent.$.throttle(250, function () {
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
      setTimeout(function () {
        id.map().centerZoom(
          [data.lon, data.lat],
          Math.max(data.zoom || 15, 13));
      }, 0);
    });
  }
});
