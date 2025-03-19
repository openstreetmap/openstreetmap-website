$(function () {
  const params = new URLSearchParams(location.search);

  if (params.has("lat") && params.has("lon")) {
    let url = "/edit";

    if (params.has("editor")) url += "?editor=" + params.get("editor");
    if (!params.has("zoom")) params.set("zoom", 17);
    url += OSM.formatHash(params);

    $(".start-mapping").attr("href", url);
  } else {
    $(".start-mapping").on("click", function (e) {
      e.preventDefault();
      $(".start-mapping").addClass("loading");

      if (navigator.geolocation) {
        // handle firefox's weird implementation
        // https://bugzilla.mozilla.org/show_bug.cgi?id=675533
        window.setTimeout(manualEdit, 4000);

        navigator.geolocation.getCurrentPosition(geoSuccess, manualEdit);
      } else {
        manualEdit();
      }
    });
  }

  function geoSuccess(position) {
    location = "/edit" + OSM.formatHash({
      zoom: 17,
      lat: position.coords.latitude,
      lon: position.coords.longitude
    });
  }

  function manualEdit() {
    location = "/?edit_help=1";
  }
});
