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

  class DownloadUtil {
    static async handleExportSuccess(fetchResponse, filename) {
      try {
        const blob = await fetchResponse.response.blob();
        OSM.downloadBlob(blob, filename);
      } catch (err) {
        OSM.showAlert(OSM.i18n.t("javascripts.share.export_failed_title"), "(blob error)");
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
      OSM.showAlert(OSM.i18n.t("javascripts.share.export_failed_title"), detailMessage);
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
  }

  OSM.getTurboBlobHandler = DownloadUtil.getTurboBlobHandler;
}());
