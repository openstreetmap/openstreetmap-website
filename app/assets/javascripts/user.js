//= require leaflet.locate

$(document).ready(function () {
  var map = L.map("map", {
    attributionControl: false,
    zoomControl: false
  }).addLayer(new L.OSM.Mapnik());

  var position = $('html').attr('dir') === 'rtl' ? 'topleft' : 'topright';

  L.OSM.zoom({position: position})
    .addTo(map);

  L.control.locate({
    position: position,
    strings: {
      title: I18n.t('javascripts.map.locate.title'),
      popup: I18n.t('javascripts.map.locate.popup')
    }
  }).addTo(map);

  if (OSM.home) {
    map.setView([OSM.home.lat, OSM.home.lon], 12);
  } else {
    map.setView([0, 0], 0);
  }

  if ($("#map").hasClass("set_location")) {
    var marker = L.marker([0, 0], {icon: OSM.getUserIcon()});

    if (OSM.home) {
      marker.setLatLng([OSM.home.lat, OSM.home.lon]);
      marker.addTo(map);
    }

    map.on("click", function (e) {
      if ($('#updatehome').is(':checked')) {
        var zoom = map.getZoom(),
            precision = OSM.zoomPrecision(zoom),
            location = e.latlng.wrap();

        $('#homerow').removeClass();
        $('#home_lat').val(location.lat.toFixed(precision));
        $('#home_lon').val(location.lng.toFixed(precision));

        marker.setLatLng(e.latlng);
        marker.addTo(map);
      }
    });
  } else {
    $("[data-user]").each(function () {
      var user = $(this).data('user');
      if (user.lon && user.lat) {
        L.marker([user.lat, user.lon], {icon: OSM.getUserIcon(user.icon)}).addTo(map)
          .bindPopup(user.description);
      }
    });
  }
});
