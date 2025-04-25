OSM.HomeLocationNameGeocoder = function Endpoint(latInput, lonInput, locationNameInput) {
  const endpoint = {
    autofill: true,
    countryName: locationNameInput.val().trim()
  };

  let requestController = null;

  endpoint.updateHomeLocationName = function (
    updateInput = true,
    lat = latInput.val().trim(),
    lon = lonInput.val().trim(),
    successFn
  ) {
    if (!lat || !lon || !endpoint.autofill) {
      return;
    }

    const geocodeUrl = "/search/nominatim_reverse_query",
          csrf_param = $("meta[name=csrf-param]").attr("content"),
          csrf_token = $("meta[name=csrf-token]").attr("content"),
          params = new URLSearchParams({
            lat,
            lon,
            zoom: 3
          });
    params.set(csrf_param, csrf_token);

    if (requestController) {
      requestController.abort();
    }
    const currentRequestController = new AbortController();
    requestController = currentRequestController;

    fetch(geocodeUrl, {
      method: "POST",
      body: params,
      signal: requestController.signal,
      headers: { accept: "application/json" }
    })
      .then((response) => response.json())
      .then((data) => {
        const country = data.length ? data[0].name : "";

        if (updateInput) {
          $("#home_location_name").val(country);
        } else if (endpoint.countryName !== country) {
          endpoint.autofill = false;
        }
        endpoint.countryName = country;
        requestController = null;

        if (successFn) {
          successFn();
        }
      })
      .catch(() => {
        if (currentRequestController === requestController) {
          requestController = null;
        }
      });
  };

  return endpoint;
};
