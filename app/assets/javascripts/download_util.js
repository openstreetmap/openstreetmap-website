(function () {
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

  class DownloadUtil {
    static async handleExportSuccess(fetchResponse, filename) {
      try {
        const blob = await fetchResponse.response.blob();
        OSM.downloadBlob(blob, filename);
      } catch (err) {
        OSM.showAlert(OSM.i18n.t("javascripts.share.export_failed", { reason: "(blob error)" }));
      }
    }

    static async handleExportError(event) {
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
      OSM.showAlert(OSM.i18n.t("javascripts.share.export_failed", { reason: detailMessage }));
    }

    static getTurboBlobHandler(filename) {
      return function (event) {
        if (event.detail.success) {
          DownloadUtil.handleExportSuccess(event.detail.fetchResponse, filename);
        } else {
          DownloadUtil.handleExportError(event);
        }
      };
    }

    static turboHtmlResponseHandler(event) {
      const response = event.detail.fetchResponse.response;
      const contentType = response.headers.get("content-type");

      if (!response.ok && contentType?.includes("text/html")) {
        // Prevent Turbo from replacing the current page with an error HTML response
        // from the export endpoint
        event.preventDefault();
        event.stopPropagation();
      }
    };
  }

  OSM.getTurboBlobHandler = DownloadUtil.getTurboBlobHandler;
  OSM.turboHtmlResponseHandler = DownloadUtil.turboHtmlResponseHandler;
}());
