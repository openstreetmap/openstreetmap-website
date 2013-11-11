OSM.Search = function(map) {
  $(".search_form input[name=query]")
    .on("focus", function() {
      $(".describe_location").fadeOut(100);
    })
    .on("blur", function() {
      $(".describe_location").fadeIn(100);
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
    var data = $(this).data(),
      center = L.latLng(data.lat, data.lon);

    if (data.type && data.id) return; // Browse link

    e.preventDefault();
    e.stopPropagation();

    if (data.minLon && data.minLat && data.maxLon && data.maxLat) {
      map.fitBounds([[data.minLat, data.minLon],
        [data.maxLat, data.maxLon]]);
    } else {
      map.setView(center, data.zoom);
    }
  }

  var marker = L.marker([0, 0], {icon: getUserIcon()});

  var page = {};

  page.pushstate = page.popstate = function(path) {
    var params = querystring.parse(path.substring(path.indexOf('?') + 1));
    $(".search_form input[name=query]").val(params.query);
    map.invalidateSize();
    $("#sidebar_content").load(path, function() {
      if (xhr.getResponseHeader('X-Page-Title')) {
        document.title = xhr.getResponseHeader('X-Page-Title');
      }
      page.load();
    });
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
    $(".search_form input[name=query]").val("");
  };

  return page;
};
