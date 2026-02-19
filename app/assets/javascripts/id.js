//= require @openstreetmap/id/dist/iD.js

/* globals iD */

(() => {
  const originalReplaceState = window.history.replaceState;
  window.history.replaceState = function (...args) {
    const result = originalReplaceState.apply(this, args);
    window.dispatchEvent(new CustomEvent("replaceHistoryState", { detail: args }));
    return result;
  };
})();

document.addEventListener("DOMContentLoaded", function () {
  const container = document.getElementById("id-container");

  if (typeof iD === "undefined" || !iD.utilDetect().support) {
    container.innerHTML = "This editor is supported " +
      "in Firefox, Chrome, Safari, Opera and Edge. " +
      "Please upgrade your browser or use JOSM to edit the map.";
    container.className = "unsupported";
  } else {
    const idContext = iD.coreContext();
    idContext.connection().apiConnections([]);
    const url = location.protocol + "//" + location.host;
    idContext.preauth({
      url: url,
      apiUrl: url.replace("www.openstreetmap.org", "api.openstreetmap.org"),
      access_token: container.dataset.token
    });

    const id = idContext
      .embed(true)
      .assetPath("@openstreetmap/id/dist/")
      .assetMap(JSON.parse(container.dataset.assetMap))
      .locale(container.dataset.locale)
      .theme(container.dataset.theme)
      .containerNode(container)
      .init();

    if (parent === window) {
      // iD not opened in an iframe -> skip setting of parent  handlers
      return;
    }

    window.addEventListener("replaceHistoryState", function () {
      if (id.inIntro()) return;
      const zoom = ~~id.map().zoom(),
            center = id.map().center(),
            llz = { lon: center[0], lat: center[1], zoom: zoom };

      parent.postMessage({ type: "hashchange", data: llz }, location.origin);
    });

    window.addEventListener("message", function (event) {
      if (event.source !== parent || event.origin !== location.origin) return;
      const msg = event.data;
      if (!msg || msg.type !== "hashchange") return;
      const data = msg.data;
      // 0ms timeout to avoid iframe JS context weirdness.
      // https://gist.github.com/jfirebaugh/5439412
      setTimeout(function () {
        id.map().centerZoom(
          [data.lon, data.lat],
          Math.max(data.zoom || 15, 13));
      }, 0);
    });

    const projectTitle = parent.document.title;
    new MutationObserver(() =>
      parent.document.title = [document.title, projectTitle].filter(t => t).join(" | ")
    ).observe(document.querySelector("title"), { childList: true, subtree: true, characterData: true });
  }
});
