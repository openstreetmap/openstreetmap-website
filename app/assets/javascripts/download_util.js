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
    OSM.showAlert(OSM.i18n.t("javascripts.share.export_failed_title"), reason);
  }

  return function ({ detail }) {
    if (detail.success) {
      handleExportSuccess(detail);
    } else {
      handleExportError(detail);
    }
  };
};

OSM.turboHtmlResponseHandler = function (event) {
  const response = event.detail.fetchResponse.response;
  const contentType = response.headers.get("content-type");
  if (!response.ok && contentType?.includes("text/html")) {
    // Prevent Turbo from replacing the current page with an error HTML response
    // from the export endpoint
    event.preventDefault();
    event.stopPropagation();
  }
};

OSM.displayLoadError = function (message, close) {
  $("#browse_status").html(
    $("<div class='p-3'>").append(
      $("<div class='d-flex'>").append(
        $("<h2 class='flex-grow-1 text-break'>")
          .text(OSM.i18n.t("browse.start_rjs.load_data")),
        $("<div>").append(
          $("<button type='button' class='btn-close'>")
            .attr("aria-label", OSM.i18n.t("javascripts.close"))
            .on("click", close))),
      $("<p class='alert alert-warning'>")
        .text(OSM.i18n.t("browse.start_rjs.feature_error", { message: message }))));
};
