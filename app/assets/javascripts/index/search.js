function initializeSearch(map) {
  $("#search_form").submit(submitSearch);
  $("#describe_location").click(describeLocation);

  if ($("#query").val()) {
    $("#search_form").submit();
  }

  $("#query")
    .on("focus", function() {
      $("#describe_location").fadeOut(100);
    })
    .on("blur", function() {
      $("#describe_location").fadeIn(100);
    });

  $("#sidebar_content").on("click", ".search_results_entry a.set_position", clickSearchResult);

  var marker = L.marker([0, 0], {icon: getUserIcon()});

  function submitSearch(e) {
    e.preventDefault();

    var bounds = map.getBounds();

    $("#sidebar_content").load($(this).attr("action"), {
      query: $("#query").val(),
      zoom: map.getZoom(),
      minlon: bounds.getWest(),
      minlat: bounds.getSouth(),
      maxlon: bounds.getEast(),
      maxlat: bounds.getNorth()
    });

    $("#sidebar").one("closed", function () {
      map.removeLayer(marker);
      map.removeObject();
    });
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

  function describeLocation(e) {
    e.preventDefault();

    var center = map.getCenter(),
      zoom = map.getZoom();

    $("#sidebar_content").load($(this).attr("href"), {
      lat: center.lat,
      lon: center.lng,
      zoom: zoom
    });
  }
}
