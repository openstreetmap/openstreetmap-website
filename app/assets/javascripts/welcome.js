$(function () {
  const mappingBtn = $(".start-mapping");
  if (!mappingBtn.attr("href").includes("#map=")) {
    mappingBtn.on("click", function (e) {
      e.preventDefault();
      mappingBtn.addClass("loading");

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
