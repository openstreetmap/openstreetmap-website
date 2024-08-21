OSM.DirectionsEndpoint = function Endpoint(map, input, iconUrl, dragCallback, changeCallback) {
  var endpoint = {};

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

  endpoint.enable = function () {
    endpoint.marker.on("drag dragend", markerDragListener);
    input.on("keydown", inputKeydownListener);
    input.on("change", inputChangeListener);
  };

  endpoint.disable = function () {
    endpoint.marker.off("drag dragend", markerDragListener);
    input.off("keydown", inputKeydownListener);
    input.off("change", inputChangeListener);

    if (endpoint.geocodeRequest) endpoint.geocodeRequest.abort();
    delete endpoint.geocodeRequest;
    removeLatLng();
    delete endpoint.value;
    input.val("");
    map.removeLayer(endpoint.marker);
  };

  function markerDragListener(e) {
    var latlng = convertLatLngToZoomPrecision(e.target.getLatLng());

    setLatLng(latlng);
    setInputValueFromLatLng(latlng);
    endpoint.value = input.val();
    dragCallback(e.type === "drag");
  }

  function inputKeydownListener() {
    input.removeClass("is-invalid");
  }

  function inputChangeListener(e) {
    // make text the same in both text boxes
    var value = e.target.value;
    endpoint.setValue(value);
  }

  endpoint.setValue = function (value, latlng) {
    endpoint.value = value;
    removeLatLng();
    input.removeClass("is-invalid");
    input.val(value);

    if (latlng) {
      setLatLng(latlng);
      setInputValueFromLatLng(latlng);
      changeCallback();
    } else if (endpoint.value) {
      getGeocode();
    }
  };

  function getGeocode() {
    var viewbox = map.getBounds().toBBoxString(); // <sw lon>,<sw lat>,<ne lon>,<ne lat>
    var geocodeUrl = OSM.NOMINATIM_URL + "search?q=" + encodeURIComponent(endpoint.value) + "&format=json&viewbox=" + viewbox;

    if (endpoint.geocodeRequest) endpoint.geocodeRequest.abort();
    endpoint.geocodeRequest = $.getJSON(geocodeUrl, function (json) {
      delete endpoint.geocodeRequest;
      if (json.length === 0) {
        input.addClass("is-invalid");
        alert(I18n.t("javascripts.directions.errors.no_place", { place: endpoint.value }));
        return;
      }

      setLatLng(L.latLng(json[0]));

      input.val(json[0].display_name);

      changeCallback();
    });
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

  function convertLatLngToZoomPrecision(latlng) {
    var precision = OSM.zoomPrecision(map.getZoom());

    return L.latLng(latlng.lat.toFixed(precision), latlng.lng.toFixed(precision));
  }

  return endpoint;
};
