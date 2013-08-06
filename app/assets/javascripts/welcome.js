$(document).ready(function() {
  var params = OSM.params();

  if (params.lat && params.lon) {
    params.lat = parseFloat(params.lat);
    params.lon = parseFloat(params.lon);
    params.zoom = params.zoom || 17;

    var url = '/edit';

    if (params.editor) {
      url += '?editor=' + params.editor;
    }

    url += OSM.formatHash(params);

    $('.start-mapping').attr('href', url);

  } else if (navigator.geolocation) {
    function geoSuccess(position) {
      window.location = '/edit' + OSM.formatHash({
        zoom: 17,
        lat: position.coords.latitude,
        lon: position.coords.longitude
      });
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
