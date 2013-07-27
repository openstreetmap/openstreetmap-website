L.OSM.share = function (options) {
  var control = L.control(options),
    marker = L.marker([0, 0], {draggable: true}),
    locationFilter = new L.LocationFilter({
      enableButton: false,
      adjustButton: false
    });

  control.onAdd = function (map) {
    var $container = $('<div>')
      .attr('class', 'control-share');

    $('<a>')
      .attr('class', 'control-button')
      .attr('href', '#')
      .attr('title', 'Share')
      .html('<span class="icon share"></span>')
      .on('click', toggle)
      .appendTo($container);

    var $ui = $('<div>')
      .attr('class', 'share-ui');

    $('<div>')
      .attr('class', 'sidebar_heading')
      .appendTo($ui)
      .append(
        $('<a>')
          .text(I18n.t('javascripts.close'))
          .attr('class', 'sidebar_close')
          .attr('href', '#')
          .bind('click', toggle))
      .append(
        $('<h4>')
          .text(I18n.t('javascripts.share.title')));

    // Link / Embed

    var $linkSection = $('<div>')
      .attr('class', 'section share-link')
      .appendTo($ui);

    $('<h4>')
      .text(I18n.t('javascripts.share.link'))
      .appendTo($linkSection);

    var $form = $('<form>')
      .attr('class', 'standard-form')
      .appendTo($linkSection);

    $('<div>')
      .attr('class', 'form-row')
      .appendTo($form)
      .append(
        $('<label>')
          .attr('for', 'link_marker')
          .append(
            $('<input>')
              .attr('id', 'link_marker')
              .attr('type', 'checkbox')
              .bind('change', toggleMarker))
          .append(I18n.t('javascripts.share.include_marker')));

    $('<div>')
      .attr('class', 'form-row')
      .appendTo($form)
      .append(
        $('<label>')
          .attr('for', 'center_marker')
          .append(
            $('<input>')
              .attr('id', 'center_marker')
              .attr('type', 'checkbox')
              .prop('checked', true)
              .bind('change', update))
          .append(I18n.t('javascripts.share.center_marker')));

    $('<div>')
      .attr('class', 'form-row')
      .appendTo($form)
      .append($('<label>')
        .attr('for', 'long_input')
        .text(I18n.t('javascripts.share.long_link')))
      .append($('<a>')
        .attr('id', 'long_link')
        .append($('<span>')
          .attr('class', 'icon link')))
      .append($('<input>')
        .attr('id', 'long_input')
        .attr('type', 'text')
        .on('click', select));

    $('<div>')
      .attr('class', 'form-row')
      .appendTo($form)
      .append($('<label>')
        .attr('for', 'short_input')
        .text(I18n.t('javascripts.share.short_link')))
      .append($('<a>')
        .attr('id', 'short_link')
        .append($('<span>')
          .attr('class', 'icon link')))
      .append($('<input>')
        .attr('id', 'short_input')
        .attr('type', 'text')
        .on('click', select));

    $('<div>')
      .attr('class', 'form-row')
      .appendTo($form)
      .append($('<label>')
        .attr('for', 'embed_html')
        .text(I18n.t('javascripts.share.embed')))
      .append(
        $('<textarea>')
          .attr('id', 'embed_html')
          .on('click', select));

    $('<p>')
      .attr('class', 'deemphasize')
      .text(I18n.t('javascripts.share.paste_html'))
      .appendTo($linkSection);

    // Image

    var $imageSection = $('<div>')
      .attr('class', 'section share-image')
      .appendTo($ui);

    $('<h4>')
      .text(I18n.t('javascripts.share.image'))
      .appendTo($imageSection);

    $form = $('<form>')
      .attr('class', 'standard-form')
      .attr('action', '/export/finish')
      .attr('method', 'post')
      .appendTo($imageSection);

    $('<div>')
      .attr('class', 'form-row')
      .appendTo($form)
      .append(
        $('<label>')
          .attr('for', 'image_filter')
          .append(
            $('<input>')
              .attr('id', 'image_filter')
              .attr('type', 'checkbox')
              .bind('change', toggleFilter))
          .append(I18n.t('javascripts.share.custom_dimensions')));

    $('<div>')
      .attr('class', 'form-row')
      .appendTo($form)
      .append(
        $('<label>')
          .attr('class', 'standard-label')
          .attr('for', 'mapnik_format')
          .text(I18n.t('javascripts.share.format')))
      .append($('<select>')
        .attr('name', 'mapnik_format')
        .attr('id', 'mapnik_format')
        .append($('<option>').val('png').text('PNG').prop('selected', true))
        .append($('<option>').val('jpeg').text('JPEG'))
        .append($('<option>').val('svg').text('SVG'))
        .append($('<option>').val('pdf').text('PDF')));

    $('<div>')
      .attr('class', 'form-row')
      .appendTo($form)
      .append($('<label>')
        .attr('class', 'standard-label')
        .attr('for', 'mapnik_scale')
        .text(I18n.t('javascripts.share.scale')))
      .append('1 : ')
      .append($('<input>')
        .attr('name', 'mapnik_scale')
        .attr('id', 'mapnik_scale')
        .attr('type', 'text')
        .on('change', update));

    ['minlon', 'minlat', 'maxlon', 'maxlat'].forEach(function(name) {
      $('<input>')
        .attr('id', 'mapnik_' + name)
        .attr('name', name)
        .attr('type', 'hidden')
        .appendTo($form);
    });

    $('<input>')
      .attr('name', 'format')
      .attr('value', 'mapnik')
      .attr('type', 'hidden')
      .appendTo($form);

    $('<p>')
      .attr('class', 'deemphasize')
      .html(I18n.t('javascripts.share.image_size') + ' <span id="mapnik_image_width"></span> x <span id="mapnik_image_height"></span>')
      .appendTo($form);

    $('<input>')
      .attr('type', 'submit')
      .attr('value', I18n.t('javascripts.share.download'))
      .appendTo($form);

    locationFilter
      .on('change', update)
      .addTo(map);

    map.on('moveend layeradd layerremove', update);
    marker.on('dragend', update);

    options.sidebar.addPane($ui);

    $ui
      .on('hide', hidden);

    function hidden() {
      map.removeLayer(marker);
      locationFilter.disable();
      update();
    }

    function toggle(e) {
      e.stopPropagation();
      e.preventDefault();

      $('#mapnik_scale').val(getScale());
      marker.setLatLng(map.getCenter());

      update();
      options.sidebar.togglePane($ui);
    }

    function toggleMarker() {
      if ($(this).is(':checked')) {
        marker.setLatLng(map.getCenter());
        map.addLayer(marker);
      } else {
        map.removeLayer(marker);
      }
      update();
    }

    function toggleFilter() {
      if ($(this).is(':checked')) {
        if (!locationFilter.getBounds().isValid()) {
          locationFilter.setBounds(map.getBounds().pad(-0.2));
        }

        locationFilter.enable();
      } else {
        locationFilter.disable();
      }
      update();
    }

    function update() {
      if (map.hasLayer(marker) && $('#center_marker').is(':checked')) {
        map.panTo(marker.getLatLng());
      }

      var bounds = map.getBounds();

      $('#link_marker')
        .prop('checked', map.hasLayer(marker));

      $('#center_marker')
        .prop('disabled', !map.hasLayer(marker));

      $('#image_filter')
        .prop('checked', locationFilter.isEnabled());

      // Link / Embed

      $('#short_input').val(map.getShortUrl(marker));
      $('#long_input').val(map.getUrl(marker));
      $('#short_link').attr('href', map.getShortUrl(marker));
      $('#long_link').attr('href', map.getUrl(marker));

      var params = {
        bbox: bounds.toBBoxString(),
        layer: map.getMapBaseLayerId()
      };

      if (map.hasLayer(marker)) {
        params.marker = marker.getLatLng().lat + ',' + marker.getLatLng().lng;
      }

      $('#embed_html').val(
        '<iframe width="425" height="350" frameborder="0" scrolling="no" marginheight="0" marginwidth="0" src="' +
          'http://' + OSM.SERVER_URL + '/export/embed.html?' + $.param(params) +
          '" style="border: 1px solid black"></iframe><br/>' +
          '<small><a href="' + map.getUrl(marker) + '</a></small>');

      // Image

      if (locationFilter.isEnabled()) {
        bounds = locationFilter.getBounds();
      }

      var scale = $("#mapnik_scale").val(),
        size = L.bounds(L.CRS.EPSG3857.project(bounds.getSouthWest()),
                        L.CRS.EPSG3857.project(bounds.getNorthEast())).getSize(),
        maxScale = Math.floor(Math.sqrt(size.x * size.y / 0.3136));

      $('#mapnik_minlon').val(bounds.getWest());
      $('#mapnik_minlat').val(bounds.getSouth());
      $('#mapnik_maxlon').val(bounds.getEast());
      $('#mapnik_maxlat').val(bounds.getNorth());

      if (scale < maxScale) {
        scale = roundScale(maxScale);
        $("#mapnik_scale").val(scale);
      }

      $("#mapnik_image_width").text(Math.round(size.x / scale / 0.00028));
      $("#mapnik_image_height").text(Math.round(size.y / scale / 0.00028));
    }

    function select() {
      $(this).select();
    }

    function getScale() {
      var bounds = map.getBounds(),
        centerLat = bounds.getCenter().lat,
        halfWorldMeters = 6378137 * Math.PI * Math.cos(centerLat * Math.PI / 180),
        meters = halfWorldMeters * (bounds.getEast() - bounds.getWest()) / 180,
        pixelsPerMeter = map.getSize().x / meters,
        metersPerPixel = 1 / (92 * 39.3701);
      return Math.round(1 / (pixelsPerMeter * metersPerPixel));
    }

    function roundScale(scale) {
      var precision = 5 * Math.pow(10, Math.floor(Math.LOG10E * Math.log(scale)) - 2);
      return precision * Math.ceil(scale / precision);
    }

    return $container[0];
  };

  return control;
};
