OSM.Search = function(map) {
  $("#query")
    .on("focus", function() {
      $("#describe_location").fadeOut(100);
    })
    .on("blur", function() {
      $("#describe_location").fadeIn(100);
    });

  $("#sidebar_content")
    .on("click", ".search_more a", clickSearchMore)
    .on("click", ".search_results_entry a.set_position", clickSearchResult);

  function clickSearchMore(e) {
    e.preventDefault();
    e.stopPropagation();

    var div = $(this).parents(".search_more");

    $(this).hide();
    div.find(".loader").show();

    $.get($(this).attr("href"), function(data) {
      div.replaceWith(data);
    });
  }

  function clickSearchResult(e) {
    e.preventDefault();
    e.stopPropagation();

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

  var marker = L.marker([0, 0], {icon: getUserIcon()});

  var page = {};

  page.pushstate = page.popstate = function(path) {
    var params = querystring.parse(path.substring(path.indexOf('?') + 1));
    $("#query").val(params.query);
    $("#sidebar").removeClass("minimized");
    map.invalidateSize();
    $("#sidebar_content").load(path, page.load);
  };

  page.load = function() {
    $(".search_results_entry").each(function() {
      var entry = $(this);
      $.ajax({
        url: entry.data("href"),
        method: 'GET',
        data: {
          zoom: map.getZoom(),
          minlon: map.getBounds().getWest(),
          minlat: map.getBounds().getSouth(),
          maxlon: map.getBounds().getEast(),
          maxlat: map.getBounds().getNorth()
        },
        success: function(html) {
          entry.html(html);
        }
      });
    });
  };

  page.unload = function() {
    map.removeLayer(marker);
    map.removeObject();
    $("#query").val("");
  };

  return page;
};
