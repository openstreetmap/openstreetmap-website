//= require jquery.simulate

OSM.Search = function(map) {
  $(".search_form input[name=query]").on("input", function(e) {
    if ($(e.target).val() === "") {
      $(".describe_location").fadeIn(100);
    } else {
      $(".describe_location").fadeOut(100);
    }
  });

  $(".search_form a.button.switch_link").on("click", function(e) {
    e.preventDefault();
    var query = $(e.target).parent().parent().find("input[name=query]").val();
    if (query) {
      OSM.router.route("/directions?from=" + encodeURIComponent(query) + OSM.formatHash(map));
    } else {
      OSM.router.route("/directions" + OSM.formatHash(map));
    }
  });

  $(".search_form").on("submit", function(e) {
    e.preventDefault();
    $("header").addClass("closed");
    var query = $(this).find("input[name=query]").val();
    if (query) {
      OSM.router.route("/search?query=" + encodeURIComponent(query) + OSM.formatHash(map));
    } else {
      OSM.router.route("/" + OSM.formatHash(map));
    }
  });

  $(".describe_location").on("click", function(e) {
    e.preventDefault();
    var center = map.getCenter().wrap(),
      precision = OSM.zoomPrecision(map.getZoom());
    OSM.router.route("/search?whereami=1&query=" + encodeURIComponent(
      center.lat.toFixed(precision) + "," + center.lng.toFixed(precision)
    ));
  });

  $("#sidebar_content")
    .on("click", ".search_more a", clickSearchMore)
    .on("click", ".search_results_entry a.set_position", clickSearchResult)
    .on("mouseover", "p.search_results_entry:has(a.set_position)", showSearchResult)
    .on("mouseout", "p.search_results_entry:has(a.set_position)", hideSearchResult)
    .on("mousedown", "p.search_results_entry:has(a.set_position)", function () {
      var moved = false;
      $(this).one("click", function (e) {
        if (!moved && !$(e.target).is('a')) {
          $(this).find("a.set_position").simulate("click", e);
        }
      }).one("mousemove", function () {
        moved = true;
      });
    });

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

  function showSearchResult() {
    var marker = $(this).data("marker");

    if (!marker) {
      var data = $(this).find("a.set_position").data();

      marker = L.marker([data.lat, data.lon], {icon: OSM.getUserIcon()});

      $(this).data("marker", marker);
    }

    markers.addLayer(marker);

    $(this).closest("li").addClass("selected");
  }

  function hideSearchResult() {
    var marker = $(this).data("marker");

    if (marker) {
      markers.removeLayer(marker);
    }

    $(this).closest("li").removeClass("selected");
  }

  function panToSearchResult(data) {
    if (data.minLon && data.minLat && data.maxLon && data.maxLat) {
      map.fitBounds([[data.minLat, data.minLon], [data.maxLat, data.maxLon]]);
    } else {
      map.setView([data.lat, data.lon], data.zoom);
    }
  }

  function clickSearchResult(e) {
    var data = $(this).data();

    panToSearchResult(data);

    // Let clicks to object browser links propagate.
    if (data.type && data.id) return;

    e.preventDefault();
    e.stopPropagation();
  }

  var markers = L.layerGroup().addTo(map);

  var page = {};

  page.pushstate = page.popstate = function(path) {
    var params = querystring.parse(path.substring(path.indexOf('?') + 1));
    $(".search_form input[name=query]").val(params.query);
    $(".describe_location").hide();
    OSM.loadSidebarContent(path, page.load);
  };

  page.load = function() {
    $(".search_results_entry").each(function(index) {
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
          // go to first result of first geocoder
          if (index === 0) {
            var firstResult = entry.find('*[data-lat][data-lon]:first').first();
            if (firstResult.length) {
              panToSearchResult(firstResult.data());
            }
          }
        }
      });
    });

    return map.getState();
  };

  page.unload = function() {
    markers.clearLayers();
    $(".search_form input[name=query]").val("");
    $(".describe_location").fadeIn(100);
  };

  return page;
};
