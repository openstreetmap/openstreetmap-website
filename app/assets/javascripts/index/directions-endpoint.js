OSM.DirectionsEndpoint = function Endpoint(map, input, iconUrl, dragCallback, geocodeCallback) {
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

  endpoint.marker.on("drag dragend", function (e) {
    var latlng = e.target.getLatLng();

    endpoint.setLatLng(latlng);
    setInputValueFromLatLng(latlng);
    endpoint.value = input.val();
    dragCallback(e.type === "drag");
  });

  input.on("keydown", function () {
    input.removeClass("is-invalid");
  });

  input.on("change", function (e) {
    // make text the same in both text boxes
    var value = e.target.value;
    endpoint.setValue(value);
  });

  endpoint.setValue = function (value, latlng) {
    endpoint.value = value;
    delete endpoint.latlng;
    input.removeClass("is-invalid");
    input.val(value);

    if (latlng) {
      endpoint.setLatLng(latlng);
      setInputValueFromLatLng(latlng);
    } else {
      endpoint.getGeocode();
    }
  };

  endpoint.getGeocode = function () {
    // if no one has entered a value yet, then we can't geocode, so don't
    // even try.
    if (!endpoint.value) {
      return;
    }

    endpoint.awaitingGeocode = true;

    var viewbox = map.getBounds().toBBoxString(); // <sw lon>,<sw lat>,<ne lon>,<ne lat>

    $.getJSON(OSM.NOMINATIM_URL + "search?q=" + encodeURIComponent(endpoint.value) + "&format=json&viewbox=" + viewbox, function (json) {
      endpoint.awaitingGeocode = false;
      endpoint.hasGeocode = true;
      if (json.length === 0) {
        input.addClass("is-invalid");
        alert(I18n.t("javascripts.directions.errors.no_place", { place: endpoint.value }));
        return;
      }

      endpoint.setLatLng(L.latLng(json[0]));

      input.val(json[0].display_name);

      geocodeCallback();
    });
  };

  endpoint.setLatLng = function (ll) {
    endpoint.hasGeocode = true;
    endpoint.latlng = ll;
    endpoint.marker
      .setLatLng(ll)
      .addTo(map);
  };

  function setInputValueFromLatLng(latlng) {
    var precision = OSM.zoomPrecision(map.getZoom());

    input.val(latlng.lat.toFixed(precision) + ", " + latlng.lng.toFixed(precision));
  }

  return endpoint;
};
