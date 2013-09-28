function initializeExport(map) {
  if (window.location.pathname == "/export") {
    startExport();
  }

  function startExport() {
    var locationFilter = new L.LocationFilter({
      enableButton: false,
      adjustButton: false
    }).addTo(map);

    update();

    locationFilter.on("change", update);

    map.on("moveend", update);

    $("#maxlat,#minlon,#maxlon,#minlat").change(boundsChanged);

    $("#drag_box").click(enableFilter);

    setBounds(map.getBounds());

    $("#sidebar").one("closed", function () {
      map.removeLayer(locationFilter);
      map.off("moveend", update);
      locationFilter.off("change", update);
    });

    function getBounds() {
      return L.latLngBounds(L.latLng($("#minlat").val(), $("#minlon").val()),
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
  }
}
