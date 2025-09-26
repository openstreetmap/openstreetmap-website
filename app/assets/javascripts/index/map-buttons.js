OSM.initializeMapButtons = function (map) {
  const queryCtrl = $(".control-query"),
        queryButton = queryCtrl.find(".control-button"),
        noteCtrl = $(".control-note"),
        noteButton = noteCtrl.find(".control-button");

  noteButton.on("click", function (e) {
    e.preventDefault();
    e.stopPropagation();

    if ($(this).hasClass("disabled")) return;

    OSM.router.route("/note/new");
  });

  queryButton.on("click", function (e) {
    e.preventDefault();
    e.stopPropagation();

    if (queryCtrl.hasClass("active")) {
      disableQueryMode();
    } else if (!queryButton.hasClass("disabled")) {
      enableQueryMode();
    }
  }).on("disabled", function () {
    if (queryCtrl.hasClass("active")) {
      map.off("click", clickHandler);
      $(map.getContainer()).removeClass("query-active").addClass("query-disabled");
      $(this).tooltip("show");
    }
  }).on("enabled", function () {
    if (queryCtrl.hasClass("active")) {
      map.on("click", clickHandler);
      $(map.getContainer()).removeClass("query-disabled").addClass("query-active");
      $(this).tooltip("hide");
    }
  });

  function clickHandler(e) {
    const [lat, lon] = OSM.cropLocation(e.latlng, map.getZoom());

    OSM.router.route("/query?" + new URLSearchParams({ lat, lon }));
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

  $(".leaflet-control .control-button").tooltip({ placement: "left", container: "body" });
};
