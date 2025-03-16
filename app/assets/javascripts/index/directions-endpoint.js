OSM.DirectionsEndpoint = function Endpoint(map, input, iconUrl, dragCallback, changeCallback) {
  const endpoint = {};

  endpoint.marker = L.marker([0, 0], {
    icon: L.icon({
      iconUrl: iconUrl,
      iconSize: [25, 41],
      iconAnchor: [12, 41],
      popupAnchor: [1, -34],
      shadowUrl: OSM.MARKER_SHADOW,
      shadowSize: [41, 41]
    }),
    draggable: true,
    autoPan: true
  });

  endpoint.enableListeners = function () {
    endpoint.marker.on("drag dragend", markerDragListener);
    input.on("keydown", inputKeydownListener);
    input.on("change", inputChangeListener);
  };

  endpoint.disableListeners = function () {
    endpoint.marker.off("drag dragend", markerDragListener);
    input.off("keydown", inputKeydownListener);
    input.off("change", inputChangeListener);
  };

  function markerDragListener(e) {
    const latlng = L.latLng(OSM.cropLocation(e.target.getLatLng(), map.getZoom()));

    if (endpoint.geocodeRequest) endpoint.geocodeRequest.abort();
    delete endpoint.geocodeRequest;

    setLatLng(latlng);
    setInputValueFromLatLng(latlng);
    endpoint.value = input.val();
    if (e.type === "dragend") getReverseGeocode();
    dragCallback(e.type === "drag");
  }

  function inputKeydownListener() {
    input.removeClass("is-invalid");
  }

  function inputChangeListener(e) {
    // make text the same in both text boxes
    const value = e.target.value;
    endpoint.setValue(value);
  }

  endpoint.setValue = function (value) {
    if (endpoint.geocodeRequest) endpoint.geocodeRequest.abort();
    delete endpoint.geocodeRequest;
    input.removeClass("is-invalid");

    const coordinatesMatch = value.match(/^\s*([+-]?\d+(?:\.\d*)?)(?:\s+|\s*[/,]\s*)([+-]?\d+(?:\.\d*)?)\s*$/);
    const latlng = coordinatesMatch && L.latLng(coordinatesMatch[1], coordinatesMatch[2]);

    if (latlng && endpoint.cachedReverseGeocode && endpoint.cachedReverseGeocode.latlng.equals(latlng)) {
      setLatLng(latlng);
      if (endpoint.cachedReverseGeocode.notFound) {
        endpoint.value = value;
        input.addClass("is-invalid");
      } else {
        endpoint.value = endpoint.cachedReverseGeocode.value;
      }
      input.val(endpoint.value);
      changeCallback();
      return;
    }

    endpoint.value = value;
    removeLatLng();
    input.val(value);

    if (latlng) {
      setLatLng(latlng);
      setInputValueFromLatLng(latlng);
      getReverseGeocode();
      changeCallback();
    } else if (endpoint.value) {
      getGeocode();
    }
  };

  endpoint.clearValue = function () {
    if (endpoint.geocodeRequest) endpoint.geocodeRequest.abort();
    delete endpoint.geocodeRequest;
    removeLatLng();
    delete endpoint.value;
    input.val("");
    map.removeLayer(endpoint.marker);
  };

  endpoint.swapCachedReverseGeocodes = function (otherEndpoint) {
    const g0 = endpoint.cachedReverseGeocode;
    const g1 = otherEndpoint.cachedReverseGeocode;
    delete endpoint.cachedReverseGeocode;
    delete otherEndpoint.cachedReverseGeocode;
    if (g0) otherEndpoint.cachedReverseGeocode = g0;
    if (g1) endpoint.cachedReverseGeocode = g1;
  };

  function getGeocode() {
    const viewbox = map.getBounds().toBBoxString(), // <sw lon>,<sw lat>,<ne lon>,<ne lat>
          geocodeUrl = OSM.NOMINATIM_URL + "search?" + new URLSearchParams({ q: endpoint.value, format: "json", viewbox });

    endpoint.geocodeRequest = new AbortController();
    fetch(geocodeUrl, { signal: endpoint.geocodeRequest.signal })
      .then(r => r.json())
      .then(success)
      .catch(() => {});

    function success(json) {
      delete endpoint.geocodeRequest;
      if (json.length === 0) {
        input.addClass("is-invalid");
        // eslint-disable-next-line no-alert
        alert(OSM.i18n.t("javascripts.directions.errors.no_place", { place: endpoint.value }));
        return;
      }

      setLatLng(L.latLng(json[0]));

      endpoint.value = json[0].display_name;
      input.val(json[0].display_name);

      changeCallback();
    }
  }

  function getReverseGeocode() {
    const latlng = endpoint.latlng.clone(),
          { lat, lng } = latlng,
          reverseGeocodeUrl = OSM.NOMINATIM_URL + "reverse?" + new URLSearchParams({ lat, lon: lng, format: "json" });

    endpoint.geocodeRequest = new AbortController();
    fetch(reverseGeocodeUrl, { signal: endpoint.geocodeRequest.signal })
      .then(r => r.json())
      .then(success)
      .catch(() => {});

    function success(json) {
      delete endpoint.geocodeRequest;
      if (!json || !json.display_name) {
        endpoint.cachedReverseGeocode = { latlng: latlng, notFound: true };
        return;
      }

      endpoint.value = json.display_name;
      input.val(json.display_name);
      endpoint.cachedReverseGeocode = { latlng: latlng, value: endpoint.value };
    }
  }

  function setLatLng(ll) {
    input
      .attr("data-lat", ll.lat)
      .attr("data-lon", ll.lng);
    endpoint.latlng = ll;
    endpoint.marker
      .setLatLng(ll)
      .addTo(map);
  }

  function removeLatLng() {
    input
      .removeAttr("data-lat")
      .removeAttr("data-lon");
    delete endpoint.latlng;
  }

  function setInputValueFromLatLng(latlng) {
    input.val(latlng.lat + ", " + latlng.lng);
  }

  return endpoint;
};
