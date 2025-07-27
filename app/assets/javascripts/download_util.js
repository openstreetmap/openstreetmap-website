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
  function handleExportSuccess({ fetchResponse }) {
    fetchResponse.response.blob()
      .then(blob => OSM.downloadBlob(blob, filename))
      .catch(() => notifyExportFailure("(blob error)"));
  }

  function handleExportError({ error, fetchResponse }) {
    Promise.resolve(
      error?.message ||
      fetchResponse.responseText.then(extractTextFromHTML)
    )
      .then(notifyExportFailure)
      .catch(() => notifyExportFailure("(unknown)"));
  }

  function extractTextFromHTML(htmlString) {
    const parser = new DOMParser();
    const doc = parser.parseFromString(htmlString, "text/html");
    return doc.body ? doc.body.textContent.trim() : "(unknown)";
  }

  function notifyExportFailure(reason) {
    OSM.showAlert(OSM.i18n.t("javascripts.share.export_failed", { reason }));
  }

  return function ({ detail }) {
    if (detail.success) {
      handleExportSuccess(detail);
    } else {
      handleExportError(detail);
    }
  };
};
