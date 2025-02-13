OSM.Export = function (map) {
  const page = {};

  const locationFilter = new L.LocationFilter({
    enableButton: false,
    adjustButton: false
  }).on("change", update);

  function getBounds() {
    return L.latLngBounds(
      L.latLng($("#minlat").val(), $("#minlon").val()),
      L.latLng($("#maxlat").val(), $("#maxlon").val()));
  }

  function boundsChanged() {
    const bounds = getBounds();
    map.fitBounds(bounds);
    locationFilter.setBounds(bounds);
    locationFilter.enable();
    validateControls();
  }

  function enableFilter(e) {
    e.preventDefault();

    $("#drag_box").hide();

    locationFilter.setBounds(map.getBounds().pad(-0.2));
    locationFilter.enable();
    validateControls();
  }

  function update() {
    setBounds(locationFilter.isEnabled() ? locationFilter.getBounds() : map.getBounds());
    validateControls();
  }

  function setBounds(bounds) {
    const truncated = [bounds.getSouthWest(), bounds.getNorthEast()]
      .map(c => OSM.cropLocation(c, map.getZoom()));
    $("#minlon").val(truncated[0][1]);
    $("#minlat").val(truncated[0][0]);
    $("#maxlon").val(truncated[1][1]);
    $("#maxlat").val(truncated[1][0]);

    $("#export_overpass").attr("href",
                               "https://overpass-api.de/api/map?bbox=" +
                               truncated.map(p => p.reverse()).join());
  }

  function validateControls() {
    $("#export_osm_too_large").toggle(getBounds().getSize() > OSM.MAX_REQUEST_AREA);
    $("#export_commit").toggle(getBounds().getSize() < OSM.MAX_REQUEST_AREA);
  }

  function checkSubmit(e) {
    if (getBounds().getSize() > OSM.MAX_REQUEST_AREA) e.preventDefault();
  }

  page.pushstate = page.popstate = function (path) {
    OSM.loadSidebarContent(path, page.load);
  };

  page.load = function () {
    map
      .addLayer(locationFilter)
      .on("moveend", update);

    $("#maxlat, #minlon, #maxlon, #minlat").change(boundsChanged);
    $("#drag_box").click(enableFilter);
    $(".export_form").on("submit", checkSubmit);

    update();
    return map.getState();
  };

  page.unload = function () {
    map
      .removeLayer(locationFilter)
      .off("moveend", update);
  };

  return page;
};
