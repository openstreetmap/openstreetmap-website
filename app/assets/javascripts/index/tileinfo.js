OSM.TileInfo = function(map) {
  var page = {},
      tile;

  page.pushstate = page.popstate = function(path) {
    OSM.loadSidebarContent(path, function () {
      page.load(path, true);
    });
  };

  page.load = function(path, noCentre) {
    var params = querystring.parse(path.substring(path.indexOf('?') + 1)),
        lat = parseFloat(params.lat),
        lon = parseFloat(params.lon),
        zoom = parseInt(params.zoom),
        layer = map.getBaseLayer(),
        pixel = map.project([lat, lon], zoom).floor(),
        tileSize = layer.getTileSize(),
        coords = pixel.unscaleBy(tileSize).floor(),
        sw = map.unproject(coords.clone().scaleBy(tileSize), zoom),
        ne = map.unproject(coords.clone().add([1, 1]).scaleBy(tileSize), zoom),
        bounds = L.latLngBounds(sw, ne),
        latlng = L.latLng(lat, lon),
        url = layer.getTileUrl(coords);

    tile = L.rectangle(bounds, {
      color: "#FF6200",
      weight: 4,
      opacity: 1,
      interactive: false
    }).addTo(map);

    $("#tileinfo-url").attr("href", url).text(url);
    $("#tileinfo-z").text(zoom);
    $("#tileinfo-y").text(coords.y);
    $("#tileinfo-x").text(coords.x);

    if (layer.options.code === "M" || layer.options.code === "H")
    {
      $.ajax({
        url: url + "/status",
        success: function (data) {
          var re = /^Tile is (.*?)\. Last rendered at (.*?)\. Last accessed at (.*?)\./,
              matches = data.match(re);

          if (matches)
          {
            var state = matches[1],
                rendered = Date.parse(matches[2]),
                accessed = Date.parse(matches[3]);

            $("#tileinfo-state").text(I18n.t("javascripts.tileinfo.state." + state));
            $("#tileinfo-rendered").text(I18n.l("time.formats.friendly", rendered));
            $("#tileinfo-accessed").text(I18n.l("time.formats.friendly", accessed));
          }
        }
      });
    }
    else
    {
      $("#tileinfo-status").hide();
    }

    if (!window.location.hash && !noCentre && !map.getBounds().contains(latlng)) {
      OSM.router.withoutMoveListener(function () {
        map.setView(latlng, zoom);
      });
    }
  };

  page.unload = function() {
    map.removeLayer(tile);
  };

  return page;
};
