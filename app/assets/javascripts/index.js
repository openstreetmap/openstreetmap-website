//= require_self
//= require index/browse
//= require index/export
//= require index/key

$(document).ready(function () {
  var permalinks = $("#permalink").html();
  var marker;
  var params = OSM.mapParams();
  var map = createMap("map");

  L.control.scale().addTo(map);

  map.attributionControl.setPrefix(permalinks);

  map.on("moveend baselayerchange", updateLocation);

  if (!params.object_zoom) {
    if (params.bbox) {
      var bbox = L.latLngBounds([params.minlat, params.minlon],
                                [params.maxlat, params.maxlon]);

      map.fitBounds(bbox);

      if (params.box) {
        addBoxToMap(bbox);
      }
    } else {
      map.setView([params.lat, params.lon], params.zoom);
    }
  }

  if (params.layers) {
    setMapLayers(params.layers);
  }

  if (params.marker) {
    marker = L.marker([params.mlat, params.mlon], {icon: getUserIcon()}).addTo(map);
  }

  if (params.object) {
    addObjectToMap(params.object, params.object_zoom);
  }

  handleResize();

  $("body").on("click", "a.set_position", function (e) {
    e.preventDefault();

    var data = $(this).data();
    var centre = L.latLng(data.lat, data.lon);

    if (data.minLon && data.minLat && data.maxLon && data.maxLat) {
      map.fitBounds([[data.minLat, data.minLon],
                     [data.maxLat, data.maxLon]]);
    } else {
      map.setView(centre, data.zoom);
    }

    if (marker) {
      map.removeLayer(marker);
    }

    marker = L.marker(centre, {icon: getUserIcon()}).addTo(map);
  });

  function updateLocation() {
    var center = map.getCenter();
    var zoom = map.getZoom();
    var layers = getMapLayers();
    var extents = map.getBounds();

    updatelinks(center.lng,
                center.lat,
                zoom,
                layers,
                extents.getWestLng(),
                extents.getSouthLat(),
                extents.getEastLng(),
                extents.getNorthLat(),
                params.object);

    var expiry = new Date();
    expiry.setYear(expiry.getFullYear() + 10);
    $.cookie("_osm_location", [center.lng, center.lat, zoom, layers].join("|"), {expires: expiry});
  }

  function remoteEditHandler() {
    var extent = map.getBounds();
    var loaded = false;

    $("#linkloader").load(function () { loaded = true; });
    $("#linkloader").attr("src", "http://127.0.0.1:8111/load_and_zoom?left=" + extent.getWestLng()
                                                                   + "&bottom=" + extent.getSouthLat()
                                                                   + "&right=" + extent.getEastLng()
                                                                   + "&top=" + extent.getNorthLat());

    setTimeout(function () {
      if (!loaded) alert(I18n.t('site.index.remote_failed'));
    }, 1000);

    return false;
  }

  $("a[data-editor=remote]").click(remoteEditHandler);

  if (OSM.preferred_editor == "remote" && $('body').hasClass("site-edit")) {
    remoteEditHandler();
  }

  $(window).resize(handleResize);

  $("#search_form").submit(function () {
    var bounds = map.getBounds();

    $("#sidebar_title").html(I18n.t('site.sidebar.search_results'));
    $("#sidebar_content").load($(this).attr("action"), {
      query: $("#query").val(),
      minlon: bounds.getWestLng(),
      minlat: bounds.getSouthLat(),
      maxlon: bounds.getEastLng(),
      maxlat: bounds.getNorthLat()
    }, openSidebar);

    return false;
  });

  if ($("#query").val()) {
    $("#search_form").submit();
  }
});
