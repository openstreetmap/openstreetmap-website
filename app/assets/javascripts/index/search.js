function initializeSearch(map) {
  $("#search_form").submit(submitSearch);

  if ($("#query").val()) {
    $("#search_form").submit();
  }

  // Focus the search field for browsers that don't support
  // the HTML5 'autofocus' attribute
  if (!("autofocus" in document.createElement("input"))) {
    $("#query").focus();
  }

  $("#sidebar_content").on("click", ".search_results_entry a.set_position", clickSearchResult);

  var marker = L.marker([0, 0], {icon: getUserIcon()});

  function submitSearch(e) {
    e.preventDefault();

    var bounds = map.getBounds();

    $("#sidebar_title").html(I18n.t('site.sidebar.search_results'));
    $("#sidebar_content").load($(this).attr("action"), {
      query: $("#query").val(),
      minlon: bounds.getWest(),
      minlat: bounds.getSouth(),
      maxlon: bounds.getEast(),
      maxlat: bounds.getNorth()
    });

    openSidebar();
  }

  function clickSearchResult(e) {
    e.preventDefault();

    var data = $(this).data(),
      center = L.latLng(data.lat, data.lon);

    if (data.minLon && data.minLat && data.maxLon && data.maxLat) {
      map.fitBounds([[data.minLat, data.minLon],
                     [data.maxLat, data.maxLon]]);
    } else {
      map.setView(center, data.zoom);
    }

    marker
      .setLatLng(center)
      .addTo(map);

    if (data.type && data.id) {
      map.addObject(data, { zoom: false, style: { opacity: 0.2, fill: false } });
    }
  }
}
