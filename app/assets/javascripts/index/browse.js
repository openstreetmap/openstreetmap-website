function initializeBrowse(map) {
  var browseBounds;
  var selectedLayer;
  var dataLayer = map.dataLayer;

  dataLayer.setStyle({
    way: {
      weight: 3,
      color: "#000000",
      opacity: 0.4
    },
    area: {
      weight: 3,
      color: "#ff0000"
    },
    node: {
      color: "#00ff00"
    }
  });

  dataLayer.isWayArea = function () {
    return false;
  };

  dataLayer.on("click", function (e) {
    onSelect(e.layer);
  });

  map.on('layeradd', function (e) {
    if (e.layer === dataLayer) {
      map.on("moveend", updateData);
      updateData();
    }
  });

  map.on('layerremove', function (e) {
    if (e.layer === dataLayer) {
      map.off("moveend", updateData);
      $('#browse_status').empty();
    }
  });

  function updateData() {
    var bounds = map.getBounds();
    if (!browseBounds || !browseBounds.contains(bounds)) {
      getData();
    }
  }

  function displayFeatureWarning(count, limit, callback) {
    $('#browse_status').html(
      $("<p class='warning'></p>")
        .text(I18n.t("browse.start_rjs.loaded_an_area_with_num_features", { num_features: count, max_features: limit }))
        .append(
          $("<input type='submit'>")
            .val(I18n.t('browse.start_rjs.load_data'))
            .click(callback)));
  }

  var dataLoader;

  function getData() {
    var bounds = map.getBounds();
    var size = bounds.getSize();

    if (size > OSM.MAX_REQUEST_AREA) {
      $('#browse_status').html(
        $("<p class='warning'></p>")
          .text(I18n.t("browse.start_rjs.unable_to_load_size", { max_bbox_size: OSM.MAX_REQUEST_AREA, bbox_size: size.toFixed(2) })));
      return;
    }

    var url = "/api/" + OSM.API_VERSION + "/map?bbox=" + bounds.toBBoxString();

    /*
     * Modern browsers are quite happy showing far more than 100 features in
     * the data browser, so increase the limit to 2000 by default, but keep
     * it restricted to 500 for IE8 and 100 for older IEs.
     */
    var maxFeatures = 2000;

    /*@cc_on
      if (navigator.appVersion < 8) {
        maxFeatures = 100;
      } else if (navigator.appVersion < 9) {
        maxFeatures = 500;
      }
    @*/

    if (dataLoader) dataLoader.abort();

    dataLoader = $.ajax({
      url: url,
      success: function (xml) {
        dataLayer.clearLayers();
        selectedLayer = null;

        var features = dataLayer.buildFeatures(xml);

        function addFeatures() {
          $('#browse_status').empty();
          dataLayer.addData(features);
        }

        if (features.length < maxFeatures) {
          addFeatures();
        } else {
          displayFeatureWarning(features.length, maxFeatures, addFeatures);
        }

        dataLoader = null;
        browseBounds = bounds;
      }
    });
  }

  function onSelect(layer) {
    // Unselect previously selected feature
    if (selectedLayer) {
      selectedLayer.setStyle(selectedLayer.originalStyle);
    }

    // Redraw in selected style
    layer.originalStyle = layer.options;
    layer.setStyle({color: '#0000ff', weight: 8});

    OSM.router.route('/browse/' + layer.feature.type + '/' + layer.feature.id);

    // Stash the currently drawn feature
    selectedLayer = layer;
  }
}
