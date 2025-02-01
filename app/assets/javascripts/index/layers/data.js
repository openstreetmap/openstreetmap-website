OSM.initializeDataLayer = function (map) {
  let dataLoader, loadedBounds;
  const dataLayer = map.dataLayer;

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

  dataLayer.on("add", function () {
    map.fire("overlayadd", { layer: this });
    map.on("moveend", updateData);
    updateData();
  });

  dataLayer.on("remove", function () {
    if (dataLoader) dataLoader.abort();
    dataLoader = null;
    map.off("moveend", updateData);
    $("#browse_status").empty();
    map.fire("overlayremove", { layer: this });
  });

  function updateData() {
    var bounds = map.getBounds();
    if (!loadedBounds || !loadedBounds.contains(bounds)) {
      getData();
    }
  }

  function displayFeatureWarning(num_features, add, cancel) {
    $("#browse_status").html(
      $("<div class='p-3'>").append(
        $("<div class='d-flex'>").append(
          $("<h2 class='flex-grow-1 text-break'>")
            .text(I18n.t("browse.start_rjs.load_data")),
          $("<div>").append(
            $("<button type='button' class='btn-close'>")
              .attr("aria-label", I18n.t("javascripts.close"))
              .click(cancel))),
        $("<p class='alert alert-warning'>")
          .text(I18n.t("browse.start_rjs.feature_warning", { num_features })),
        $("<input type='submit' class='btn btn-primary d-block mx-auto'>")
          .val(I18n.t("browse.start_rjs.load_data"))
          .click(add)));
  }

  function displayLoadError(message, close) {
    $("#browse_status").html(
      $("<div class='p-3'>").append(
        $("<div class='d-flex'>").append(
          $("<h2 class='flex-grow-1 text-break'>")
            .text(I18n.t("browse.start_rjs.load_data")),
          $("<div>").append(
            $("<button type='button' class='btn-close'>")
              .attr("aria-label", I18n.t("javascripts.close"))
              .click(close))),
        $("<p class='alert alert-warning'>")
          .text(I18n.t("browse.start_rjs.feature_error", { message: message }))));
  }

  function getData() {
    var bounds = map.getBounds();
    var url = "/api/" + OSM.API_VERSION + "/map?bbox=" + bounds.toBBoxString();

    /*
     * Modern browsers are quite happy showing far more than 100 features in
     * the data browser, so increase the limit to 4000 by default.
     */
    const maxFeatures = 4000;

    if (dataLoader) dataLoader.abort();

    dataLoader = $.ajax({
      url: url,
      dataType: "json",
      success: function (data) {
        dataLayer.clearLayers();

        var features = dataLayer.buildFeatures(data);

        function addFeatures() {
          $("#browse_status").empty();
          dataLayer.addData(features);
          loadedBounds = bounds;
        }

        function cancelAddFeatures() {
          $("#browse_status").empty();
        }

        if (features.length < maxFeatures) {
          addFeatures();
        } else {
          displayFeatureWarning(features.length, addFeatures, cancelAddFeatures);
        }

        if (map._objectLayer) {
          map._objectLayer.bringToFront();
        }

        dataLoader = null;
      },
      error: function (XMLHttpRequest, textStatus) {
        dataLoader = null;
        if (textStatus === "abort") { return; }

        function closeError() {
          $("#browse_status").empty();
        }

        if (XMLHttpRequest.status === 400 && XMLHttpRequest.responseText) {
          displayLoadError(XMLHttpRequest.responseText, closeError);
        } else if (XMLHttpRequest.statusText) {
          displayLoadError(XMLHttpRequest.statusText, closeError);
        } else {
          displayLoadError(String(XMLHttpRequest.status), closeError);
        }
      }
    });
  }

  function onSelect(layer) {
    OSM.router.route("/" + layer.feature.type + "/" + layer.feature.id);
  }
};
