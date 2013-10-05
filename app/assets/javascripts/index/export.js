OSM.Export = function(map) {
  var page = {};

  var locationFilter = new L.LocationFilter({
    enableButton: false,
    adjustButton: false
  }).on("change", update);

  function getBounds() {
    return L.latLngBounds(
      L.latLng($("#minlat").val(), $("#minlon").val()),
      L.latLng($("#maxlat").val(), $("#maxlon").val()));
  }

  function boundsChanged() {
    var bounds = getBounds();

    map.fitBounds(bounds);
    locationFilter.setBounds(bounds);

    enableFilter();
    validateControls();
  }

  function enableFilter() {
    if (!locationFilter.getBounds().isValid()) {
      locationFilter.setBounds(map.getBounds().pad(-0.2));
    }

    $("#drag_box").hide();
    locationFilter.enable();
  }

  function update() {
    setBounds(locationFilter.isEnabled() ? locationFilter.getBounds() : map.getBounds());
    validateControls();
  }

  function setBounds(bounds) {
    var precision = zoomPrecision(map.getZoom());
    $("#minlon").val(bounds.getWest().toFixed(precision));
    $("#minlat").val(bounds.getSouth().toFixed(precision));
    $("#maxlon").val(bounds.getEast().toFixed(precision));
    $("#maxlat").val(bounds.getNorth().toFixed(precision));
  }

  function validateControls() {
    $("#export_osm_too_large").toggle(getBounds().getSize() > OSM.MAX_REQUEST_AREA);
  }

  page.pushstate = page.popstate = function(path) {
    $("#export_tab").addClass("current");
    $("#sidebar").removeClass("minimized");
    map.invalidateSize();
    $('#sidebar_content').load(path, page.load);
  };

  page.load = function() {
    map
      .addLayer(locationFilter)
      .on("moveend", update);

    $("#maxlat, #minlon, #maxlon, #minlat").change(boundsChanged);
    $("#drag_box").click(enableFilter);

    update();
  };

  page.unload = function() {
    map
      .removeLayer(locationFilter)
      .off("moveend", update);

    $("#export_tab").removeClass("current");
  };

  return page;
};
