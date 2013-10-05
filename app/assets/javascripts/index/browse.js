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
    }
  });

  function updateData() {
    if (map.getZoom() >= 15) {
      var bounds = map.getBounds();
      if (!browseBounds || !browseBounds.contains(bounds)) {
        browseBounds = bounds;
        getData();
      }
    } else {
      setStatus(I18n.t('browse.start_rjs.zoom_or_select'));
    }
  }

  function displayFeatureWarning(count, limit, callback) {
    clearStatus();

    var div = document.createElement("div");

    var p = document.createElement("p");
    p.appendChild(document.createTextNode(I18n.t("browse.start_rjs.loaded_an_area_with_num_features", { num_features: count, max_features: limit })));
    div.appendChild(p);

    var input = document.createElement("input");
    input.type = "submit";
    input.value = I18n.t('browse.start_rjs.load_data');
    input.onclick = callback;
    div.appendChild(input);

    $("#browse_content").html("");
    $("#browse_content").append(div);
  }

  var dataLoader;

  function getData() {
    var bounds = map.getBounds();
    var size = bounds.getSize();

    if (size > OSM.MAX_REQUEST_AREA) {
      setStatus(I18n.t("browse.start_rjs.unable_to_load_size", { max_bbox_size: OSM.MAX_REQUEST_AREA, bbox_size: size }));
      return;
    }

    setStatus(I18n.t('browse.start_rjs.loading'));

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
        clearStatus();

        dataLayer.clearLayers();
        selectedLayer = null;

        var features = dataLayer.buildFeatures(xml);

        function addFeatures() {
          dataLayer.addData(features);
        }

        if (features.length < maxFeatures) {
          addFeatures();
        } else {
          displayFeatureWarning(features.length, maxFeatures, addFeatures);
        }

        dataLoader = null;
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

    OSM.route('/browse/' + layer.feature.type + '/' + layer.feature.id);

    // Stash the currently drawn feature
    selectedLayer = layer;
  }

  function setStatus(status) {
  }

  function clearStatus() {
  }
}
