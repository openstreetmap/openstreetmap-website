//= require download_util
OSM.initializeDataLayer = function (map) {
  let dataLoader, loadedBounds;
  const dataLayer = map.dataLayer;

  dataLayer.isWayArea = function () {
    return false;
  };

  dataLayer.on("click", function (e) {
    const feature = e.layer.feature;
    OSM.router.click(e.originalEvent, `/${feature.type}/${feature.id}`);
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
    const bounds = map.getBounds();
    if (!loadedBounds || !loadedBounds.contains(bounds)) {
      getData();
    }
  }

  function displayFeatureWarning(num_features, add, cancel) {
    $("#browse_status").html(
      $("<div class='p-3'>").append(
        $("<div class='d-flex'>").append(
          $("<h2 class='flex-grow-1 text-break'>")
            .text(OSM.i18n.t("browse.start_rjs.load_data")),
          $("<div>").append(
            $("<button type='button' class='btn-close'>")
              .attr("aria-label", OSM.i18n.t("javascripts.close"))
              .click(cancel))),
        $("<p class='alert alert-warning'>")
          .text(OSM.i18n.t("browse.start_rjs.feature_warning", { num_features })),
        $("<input type='submit' class='btn btn-primary d-block mx-auto'>")
          .val(OSM.i18n.t("browse.start_rjs.load_data"))
          .click(add)));
  }

  function getData() {
    /*
     * Modern browsers are quite happy showing far more than 100 features in
     * the data browser, so increase the limit to 4000.
     */
    const maxFeatures = 4000;
    const bounds = map.getBounds();

    if (dataLoader) dataLoader.abort();

    $("#layers-data-loading").remove();

    const spanLoading = $("<span>")
      .attr("id", "layers-data-loading")
      .attr("class", "spinner-border spinner-border-sm ms-1")
      .attr("role", "status")
      .html("<span class='visually-hidden'>" + OSM.i18n.t("browse.start_rjs.loading") + "</span>")
      .appendTo($("#label-layers-data"));

    dataLoader = new AbortController();

    function getWrappedBounds(bounds) {
      const sw = bounds.getSouthWest().wrap();
      const ne = bounds.getNorthEast().wrap();
      return {
        minLat: sw.lat,
        minLng: sw.lng,
        maxLat: ne.lat,
        maxLng: ne.lng
      };
    }

    function getRequestBounds(bounds) {
      const wrapped = getWrappedBounds(bounds);
      if (wrapped.minLng > wrapped.maxLng) {
        // BBox is crossing antimeridian: split into two bboxes in order to stay
        // within OSM API's map endpoint permitted range for longitude [-180..180].
        return [
          L.latLngBounds([wrapped.minLat, wrapped.minLng], [wrapped.maxLat, 180]),
          L.latLngBounds([wrapped.minLat, -180], [wrapped.maxLat, wrapped.maxLng])
        ];
      }
      return [L.latLngBounds([wrapped.minLat, wrapped.minLng], [wrapped.maxLat, wrapped.maxLng])];
    }

    function fetchDataForBounds(bounds) {
      return fetch(`/api/${OSM.API_VERSION}/map.json?bbox=${bounds.toBBoxString()}`, {
        headers: { ...OSM.oauth },
        signal: dataLoader.signal
      });
    }

    const requestBounds = getRequestBounds(bounds);
    const requests = requestBounds.map(fetchDataForBounds);

    Promise.all(requests)
      .then(responses =>
        Promise.all(
          responses.map(async response => {
            if (response.ok) {
              return response.json();
            }

            const status = response.statusText || response.status;
            if (response.status !== 400 && response.status !== 509) {
              throw new Error(status);
            }

            const text = await response.text();
            throw new Error(text || status);
          })
        )
      )
      .then(dataArray => {
        dataLayer.clearLayers();
        const allElements = dataArray.flatMap(item => item.elements);
        const originalFeatures = dataLayer.buildFeatures({ elements: allElements });
        // clone features when crossing antimeridian to work around Leaflet restrictions
        const features = requestBounds.length > 1 ?
          [...originalFeatures, ...cloneFeatures(originalFeatures)] : originalFeatures;

        function addFeatures() {
          $("#browse_status").empty();
          dataLayer.addData(features);
          loadedBounds = bounds;
        }

        function cancelAddFeatures() {
          $("#browse_status").empty();
        }

        if (features.length < maxFeatures * requestBounds.length) {
          addFeatures();
        } else {
          displayFeatureWarning(features.length, addFeatures, cancelAddFeatures);
        }

        if (map._objectLayer) {
          map._objectLayer.bringToFront();
        }
      })
      .catch(function (error) {
        if (error.name === "AbortError") return;

        OSM.displayLoadError(error?.message, () => {
          $("#browse_status").empty();
        });
      })
      .finally(() => {
        dataLoader = null;
        spanLoading.remove();
      });
  }

  function cloneFeatures(features) {
    const offset = map.getCenter().lng < 0 ? -360 : 360;

    const cloneNode = ({ latLng, ...rest }) => ({
      ...rest,
      latLng: { ...latLng, lng: latLng.lng + offset }
    });

    return features.flatMap(feature => {
      if (feature.type === "node") {
        return [cloneNode(feature)];
      }

      if (feature.type === "way") {
        const clonedNodes = feature.nodes.map(cloneNode);
        return [{ ...feature, nodes: clonedNodes }];
      }

      return [];
    });
  }
};
