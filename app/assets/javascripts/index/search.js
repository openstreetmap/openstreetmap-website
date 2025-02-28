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
    const query = $(this).closest("form").find("input[name=query]").val();
    let search = "";
    if (query) search = "?" + new URLSearchParams({ to: query });
    OSM.router.route("/directions" + search + OSM.formatHash(map));
  });

  $(".search_form").on("submit", function (e) {
    e.preventDefault();
    $("header").addClass("closed");
    const query = $(this).find("input[name=query]").val();
    let search = "/";
    if (query) search = "/search?" + new URLSearchParams({ query });
    OSM.router.route(search + OSM.formatHash(map));
  });

  $(".describe_location").on("click", function (e) {
    e.preventDefault();
    $("header").addClass("closed");
    const [lat, lon] = OSM.cropLocation(map.getCenter(), map.getZoom());

    OSM.router.route("/search?" + new URLSearchParams({ lat, lon }));
  });

  $("#sidebar_content")
    .on("click", ".search_more a", clickSearchMore)
    .on("click", ".search_results_entry a.set_position", clickSearchResult)
    .on("mouseover", "li.search_results_entry:has(a.set_position)", showSearchResult)
    .on("mouseout", "li.search_results_entry:has(a.set_position)", hideSearchResult);

  const markers = L.layerGroup().addTo(map);

  function clickSearchMore(e) {
    e.preventDefault();
    e.stopPropagation();

    const div = $(this).parents(".search_more");

    $(this).hide();
    div.find(".loader").show();

    fetch($(this).attr("href"), {
      method: "POST",
      body: new URLSearchParams(OSM.csrf)
    })
      .then(response => response.text())
      .then(data => div.replaceWith(data));
  }

  function showSearchResult() {
    let marker = $(this).data("marker");

    if (!marker) {
      const data = $(this).find("a.set_position").data();

      marker = L.marker([data.lat, data.lon], { icon: OSM.getUserIcon() });

      $(this).data("marker", marker);
    }

    markers.addLayer(marker);
  }

  function hideSearchResult() {
    const marker = $(this).data("marker");

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
    const data = $(this).data();

    panToSearchResult(data);

    // Let clicks to object browser links propagate.
    if (data.type && data.id) return;

    e.preventDefault();
    e.stopPropagation();
  }

  const page = {};

  page.pushstate = page.popstate = function (path) {
    const params = new URLSearchParams(path.substring(path.indexOf("?")));
    if (params.has("query")) {
      $(".search_form input[name=query]").val(params.get("query"));
      $(".describe_location").hide();
    } else if (params.has("lat") && params.has("lon")) {
      $(".search_form input[name=query]").val(params.get("lat") + ", " + params.get("lon"));
      $(".describe_location").hide();
    }
    OSM.loadSidebarContent(path, page.load);
  };

  page.load = function () {
    $(".search_results_entry").each(function (index) {
      const entry = $(this);
      fetch(entry.data("href"), {
        method: "POST",
        body: new URLSearchParams({
          zoom: map.getZoom(),
          minlon: map.getBounds().getWest(),
          minlat: map.getBounds().getSouth(),
          maxlon: map.getBounds().getEast(),
          maxlat: map.getBounds().getNorth(),
          ...OSM.csrf
        })
      })
        .then(response => response.text())
        .then(function (html) {
          entry.html(html);
          // go to first result of first geocoder
          if (index === 0) {
            const firstResult = entry.find("*[data-lat][data-lon]:first").first();
            if (firstResult.length) {
              panToSearchResult(firstResult.data());
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
