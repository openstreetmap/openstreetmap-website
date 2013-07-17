$(document).ready(function() {
  var params = OSM.params();

  if (params.lat && params.lon) {
    $('.edit-located').show();

    $.ajax({
      url: "http://nominatim.openstreetmap.org/reverse",
      data: {
        lat: params.lat,
        lon: params.lon,
        zoom: 10
      },
      success: function(xml) {
        var result = $(xml).find('result');
        if (result.length) {
          $('.edit-located').hide();
          $('.edit-geocoded').show();
          $('.edit-geocoded-location').text(result.text());
        }
      }
    });

    $('.start-mapping').on('click', function(e) {
      window.location = '/edit?zoom=17&lat=' + params.lat + '&lon=' + params.lon;
    });

  } else if (navigator.geolocation) {
    $('.edit-geolocated').show();

    function geoSuccess(position) {
      window.location = '/edit?zoom=17&lat=' + position.coords.latitude + '&lon=' + position.coords.longitude;
    }

    function geoError() {
      $('.start-mapping')
        .removeClass('loading')
        .addClass('error');
    }

    $('.start-mapping').on('click', function(e) {
      e.preventDefault();

      $('.start-mapping')
        .addClass('loading');

      // handle firefox's weird implementation
      // https://bugzilla.mozilla.org/show_bug.cgi?id=675533
      window.setTimeout(geoError, 4000);

      navigator.geolocation.getCurrentPosition(geoSuccess, geoError);
    });
  }
});
