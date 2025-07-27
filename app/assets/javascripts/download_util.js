OSM.downloadBlob = function (blob, filename) {
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
};

OSM.showAlert = function (message) {
  const modalBody = document.getElementById("osm_alert_message");
  modalBody.textContent = message;
  const alertModal = new bootstrap.Modal(document.getElementById("osm_alert_modal"));
  alertModal.show();
};

OSM.getTurboBlobHandler = function (filename) {
  async function handleExportSuccess(fetchResponse, filename) {
    try {
      const blob = await fetchResponse.response.blob();
      OSM.downloadBlob(blob, filename);
    } catch (err) {
      notifyExportFailure("(blob error)");
    }
  }

  async function handleExportError(event) {
    let detailMessage;
    try {
      detailMessage = event?.detail?.error?.message;
      if (!detailMessage) {
        const responseText = await event.detail.fetchResponse.responseText;
        detailMessage = extractTextFromHTML(responseText);
      }
    } catch (err) {
      detailMessage = "(unknown)";
    }
    notifyExportFailure(detailMessage);
  }

  function extractTextFromHTML(htmlString) {
    const parser = new DOMParser();
    const doc = parser.parseFromString(htmlString, "text/html");
    return doc.body ? doc.body.textContent.trim() : "(unknown)";
  }

  function notifyExportFailure(reason) {
    OSM.showAlert(OSM.i18n.t("javascripts.share.export_failed", { reason }));
  }

  return function (event) {
    if (event.detail.success) {
      handleExportSuccess(event.detail.fetchResponse, filename);
    } else {
      handleExportError(event);
    }
  };
};
