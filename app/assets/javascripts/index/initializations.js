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
    $(".navbar-toggler:not(.collapsed)").trigger("click");
    const bounds = map.getBounds();
    const params = new URLSearchParams({
      query: this.elements.query.value,
      zoom: map.getZoom(),
      minlon: bounds.getWest(),
      minlat: bounds.getSouth(),
      maxlon: bounds.getEast(),
      maxlat: bounds.getNorth()
    });
    const search = params.get("query") ? `/search?${params}` : "/";
    OSM.router.route(search + OSM.formatHash(map));
  });

  $(".describe_location").on("click", function (e) {
    e.preventDefault();
    $(".navbar-toggler:not(.collapsed)").trigger("click");
    const zoom = map.getZoom();
    const { lat, lng } = OSM.cropLocation(map.getCenter(), zoom);

    OSM.router.route("/search?" + new URLSearchParams({ lat, lon: lng, zoom }));
  });
});

OSM.initializations.push(function () {
  $(".control-note .control-button").on("click", function (e) {
    e.preventDefault();
    e.stopPropagation();

    if ($(this).hasClass("disabled")) return;

    OSM.router.route("/note/new");
  });
});

OSM.initializations.push(function (map) {
  const control = $(".control-query"),
        queryButton = control.find(".control-button");

  queryButton.on("click", function (e) {
    e.preventDefault();
    e.stopPropagation();

    if (control.hasClass("active")) {
      disableQueryMode();
    } else if (!queryButton.hasClass("disabled")) {
      enableQueryMode();
    }
  }).on("disabled", function () {
    if (control.hasClass("active")) {
      map.off("click", clickHandler);
      $(map.getContainer()).removeClass("query-active").addClass("query-disabled");
      $(this).tooltip("show");
    }
  }).on("enabled", function () {
    if (control.hasClass("active")) {
      map.on("click", clickHandler);
      $(map.getContainer()).removeClass("query-disabled").addClass("query-active");
      $(this).tooltip("hide");
    }
  });

  function clickHandler(e) {
    const { lat, lng } = OSM.cropLocation(e.latlng, map.getZoom());

    OSM.router.route("/query?" + new URLSearchParams({ lat, lon: lng }));
  }

  function enableQueryMode() {
    $(".control-query").addClass("active");
    map.on("click", clickHandler);
    $(map.getContainer()).addClass("query-active");
  }

  function disableQueryMode() {
    $(map.getContainer()).removeClass("query-active").removeClass("query-disabled");
    map.off("click", clickHandler);
    $(".control-query").removeClass("active");
  }
});
