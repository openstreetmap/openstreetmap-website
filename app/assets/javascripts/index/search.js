//= require qs/dist/qs

OSM.Search = function (map) {
  $(".search_form input[name=query]").on("input", function (e) {
    if ($(e.target).val() === "") {
      $(".describe_location").fadeIn(100);
    } else {
      $(".describe_location").fadeOut(100);
    }
  });

  $(".search_form a.btn.switch_link").on("click", function (e) {
    e.preventDefault();
    var query = $(this).closest("form").find("input[name=query]").val();
    if (query) {
      OSM.router.route("/directions?from=" + encodeURIComponent(query) + OSM.formatHash(map));
    } else {
      OSM.router.route("/directions" + OSM.formatHash(map));
    }
  });

  $(".search_form").on("submit", function (e) {
    e.preventDefault();
    $("header").addClass("closed");
    var query = $(this).find("input[name=query]").val();
    if (query) {
      OSM.router.route("/search?query=" + encodeURIComponent(query) + OSM.formatHash(map));
    } else {
      OSM.router.route("/" + OSM.formatHash(map));
    }
  });

  $(".describe_location").on("click", function (e) {
    e.preventDefault();
    $("header").addClass("closed");
    var center = map.getCenter().wrap(),
        precision = OSM.zoomPrecision(map.getZoom()),
        lat = center.lat.toFixed(precision),
        lng = center.lng.toFixed(precision);

    OSM.router.route("/search?lat=" + encodeURIComponent(lat) + "&lon=" + encodeURIComponent(lng));
  });

  $("#sidebar_content")
    .on("click", ".search_more a", clickSearchMore)
    .on("click", ".search_results_entry a.set_position", clickSearchResult)
    .on("mouseover", "li.search_results_entry:has(a.set_position)", showSearchResult)
    .on("mouseout", "li.search_results_entry:has(a.set_position)", hideSearchResult);

  var markers = L.layerGroup().addTo(map);

  function clickSearchMore(e) {
    e.preventDefault();
    e.stopPropagation();

    var div = $(this).parents(".search_more"),
        csrf_param = $("meta[name=csrf-param]").attr("content"),
        csrf_token = $("meta[name=csrf-token]").attr("content"),
        params = {};

    $(this).hide();
    div.find(".loader").show();

    params[csrf_param] = csrf_token;

    $.ajax({
      url: $(this).attr("href"),
      method: "POST",
      data: params,
      success: function (data) {
        div.replaceWith(data);
      }
    });
  }

  function showSearchResult() {
    var marker = $(this).data("marker");

    if (!marker) {
      var data = $(this).find("a.set_position").data();

      marker = L.marker([data.lat, data.lon], { icon: OSM.getUserIcon() });

      $(this).data("marker", marker);
    }

    markers.addLayer(marker);
  }

  function hideSearchResult() {
    var marker = $(this).data("marker");

    if (marker) {
      markers.removeLayer(marker);
    }
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

  var page = {};

  page.pushstate = page.popstate = function (path) {
    var params = Qs.parse(path.substring(path.indexOf("?") + 1));
    if (params.query) {
      $(".search_form input[name=query]").val(params.query);
      $(".describe_location").hide();
    } else if (params.lat && params.lon) {
      $(".search_form input[name=query]").val(params.lat + ", " + params.lon);
      $(".describe_location").hide();
    }
    OSM.loadSidebarContent(path, page.load);
  };

  page.load = function () {
    $(".search_results_entry").each(function (index) {
      var entry = $(this),
          csrf_param = $("meta[name=csrf-param]").attr("content"),
          csrf_token = $("meta[name=csrf-token]").attr("content"),
          params = {
            zoom: map.getZoom(),
            minlon: map.getBounds().getWest(),
            minlat: map.getBounds().getSouth(),
            maxlon: map.getBounds().getEast(),
            maxlat: map.getBounds().getNorth()
          };
      params[csrf_param] = csrf_token;
      $.ajax({
        url: entry.data("href"),
        method: "POST",
        data: params,
        success: function (html) {
          entry.html(html);
          // go to first result of first geocoder
          if (index === 0) {
            var firstResult = entry.find("*[data-lat][data-lon]:first").first();
            if (firstResult.length) {
              panToSearchResult(firstResult.data());
            }
          }
        }
      });
    });

    return map.getState();
  };

  page.unload = function () {
    markers.clearLayers();
    $(".search_form input[name=query]").val("");
    $(".describe_location").fadeIn(100);
  };

  return page;
};
