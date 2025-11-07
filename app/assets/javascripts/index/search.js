OSM.initializations.push(function (map) {
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
    const params = new URLSearchParams({
      query: this.elements.query.value,
      zoom: map.getZoom(),
      minlon: map.getBounds().getWest(),
      minlat: map.getBounds().getSouth(),
      maxlon: map.getBounds().getEast(),
      maxlat: map.getBounds().getNorth()
    });
    const search = params.get("query") ? `/search?${params}` : "/";
    OSM.router.route(search + OSM.formatHash(map));
  });

  $(".describe_location").on("click", function (e) {
    e.preventDefault();
    $("header").addClass("closed");
    const zoom = map.getZoom();
    const [lat, lon] = OSM.cropLocation(map.getCenter(), zoom);

    OSM.router.route("/search?" + new URLSearchParams({ lat, lon, zoom }));
  });
});

OSM.Search = function (map) {
  $("#sidebar_content")
    .on("click", ".search_more a", clickSearchMore)
    .on("click", ".search_results_entry a.set_position", clickSearchResult);

  const markers = L.layerGroup().addTo(map);
  let processedResults = 0;

  function clickSearchMore(e) {
    e.preventDefault();
    e.stopPropagation();

    const div = $(this).parents(".search_more");

    $(this).hide();
    div.find(".loader").prop("hidden", false);

    fetchReplace(this, div);
  }

  function fetchReplace({ href }, $target) {
    return fetch(href, {
      method: "POST",
      body: new URLSearchParams(OSM.csrf)
    })
      .then(response => response.text())
      .then(html => {
        const result = $(html);
        $target.replaceWith(result);
        result.filter("ul").children().each(showSearchResult);
      });
  }

  function showSearchResult() {
    const index = processedResults++;
    const listItem = $(this);
    const inverseGoldenAngle = (Math.sqrt(5) - 1) * 180;
    const color = `hwb(${(index * inverseGoldenAngle) % 360}deg 5% 5%)`;
    listItem.css("--marker-color", color);
    const data = listItem.find("a.set_position").data();
    const marker = L.marker([data.lat, data.lon], { icon: OSM.getMarker({ color, className: "activatable" }) });
    marker.on("mouseover", () => listItem.addClass("bg-body-secondary"));
    marker.on("mouseout", () => listItem.removeClass("bg-body-secondary"));
    marker.on("click", function (e) {
      OSM.router.click(e.originalEvent, listItem.find("a.set_position").attr("href"));
    });
    markers.addLayer(marker);
    listItem.on("mouseover", () => $(marker.getElement()).addClass("active"));
    listItem.on("mouseout", () => $(marker.getElement()).removeClass("active"));
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
    } else if (params.has("lat") && params.has("lon")) {
      $(".search_form input[name=query]").val(params.get("lat") + ", " + params.get("lon"));
    }
    OSM.loadSidebarContent(path, page.load);
  };

  page.load = function () {
    $(".search_results_entry[data-href]").each(function (index) {
      const entry = $(this);
      fetchReplace(this.dataset, entry.children().first())
        .then(() => {
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
    processedResults = 0;
  };

  return page;
};
