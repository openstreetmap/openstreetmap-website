$(function () {
  const mappingBtn = $(".start-mapping");
  if (!mappingBtn.prop("hash")) {
    mappingBtn.on("click", function (e) {
      e.preventDefault();
      mappingBtn.addClass("loading");

      if (navigator.geolocation) {
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
