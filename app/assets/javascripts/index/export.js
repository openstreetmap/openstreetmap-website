OSM.Export = function (map) {
  const page = {};

  const locationFilter = new L.LocationFilter({
    enableButton: false,
    adjustButton: false
  }).on("change", update);

  function getBounds() {
    return L.latLngBounds(
      L.latLng($("#minlat").val(), $("#minlon").val()),
      L.latLng($("#maxlat").val(), $("#maxlon").val()));
  }

  function boundsChanged() {
    const bounds = getBounds();
    map.fitBounds(bounds);
    locationFilter.setBounds(bounds);
    locationFilter.enable();
    validateControls();
  }

  function enableFilter(e) {
    e.preventDefault();

    $("#drag_box").hide();

    locationFilter.setBounds(map.getBounds().pad(-0.2));
    locationFilter.enable();
    validateControls();
  }

  function update() {
    setBounds(locationFilter.isEnabled() ? locationFilter.getBounds() : map.getBounds());
    validateControls();
  }

  function setBounds(bounds) {
    const truncated = [bounds.getSouthWest(), bounds.getNorthEast()]
      .map(c => OSM.cropLocation(c, map.getZoom()));
    $("#minlon").val(truncated[0][1]);
    $("#minlat").val(truncated[0][0]);
    $("#maxlon").val(truncated[1][1]);
    $("#maxlat").val(truncated[1][0]);

    $("#export_overpass").attr("href",
                               "https://overpass-api.de/api/map?bbox=" +
                               truncated.map(p => p.reverse()).join());
  }

  function validateControls() {
    $("#export_osm_too_large").toggle(getBounds().getSize() > OSM.MAX_REQUEST_AREA);
    $("#export_commit").toggle(getBounds().getSize() < OSM.MAX_REQUEST_AREA);
  }

  function checkSubmit(e) {
    if (getBounds().getSize() > OSM.MAX_REQUEST_AREA) e.preventDefault();
  }

  page.pushstate = page.popstate = function (path) {
    OSM.loadSidebarContent(path, page.load);
  };

  page.load = function () {
    map
      .addLayer(locationFilter)
      .on("moveend", update);

    $("#maxlat, #minlon, #maxlon, #minlat").change(boundsChanged);
    $("#drag_box").click(enableFilter);
    $(".export_form").on("submit", checkSubmit);

    function downloadBlob(blob, filename) {
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = filename;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    }

    async function handleExportSuccess(fetchResponse) {
      try {
        const blob = await fetchResponse.response.blob();
        downloadBlob(blob, "map.osm");
      } catch (err) {
        // eslint-disable-next-line no-alert
        alert(OSM.i18n.t("javascripts.share.export_failed", { reason: "(blob error)" }));
      }
    }

    async function handleExportError(event) {
      let detailMessage;
      try {
        detailMessage = event?.detail?.error?.message;
        if (!detailMessage) {
          const responseText = await event.detail.fetchResponse.responseText;
          const parser = new DOMParser();
          const doc = parser.parseFromString(responseText, "text/html");
          detailMessage = doc.body ? doc.body.textContent.trim() : "(unknown)";
        }
      } catch (err) {
        detailMessage = "(unknown)";
      }
      // eslint-disable-next-line no-alert
      alert(OSM.i18n.t("javascripts.share.export_failed", { reason: detailMessage }));
    }

    document.querySelector(".export_form").addEventListener("turbo:submit-end", function (event) {
      if (event.detail.success) {
        handleExportSuccess(event.detail.fetchResponse);
      } else {
        handleExportError(event);
      }
    });

    document.querySelector(".export_form").addEventListener("turbo:before-fetch-request", function (event) {
      event.detail.fetchOptions.headers.Accept = "application/xml";
    });

    update();
    return map.getState();
  };

  page.unload = function () {
    map
      .removeLayer(locationFilter)
      .off("moveend", update);
  };

  return page;
};
