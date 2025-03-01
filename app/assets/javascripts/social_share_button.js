$(function () {
  function openShareUrl(url, initialWidth = 640, initialHeight = 480) {
    const width = Math.max(100, Math.min(screen.width, initialWidth));
    const height = Math.max(100, Math.min(screen.height, initialHeight));

    const left = screenLeft + ((outerWidth - width) / 2);
    const top = screenTop + ((outerHeight - height) / 2);
    const opts = `width=${width},height=${height},left=${left},top=${top},menubar=no,status=no,location=no`;

    window.open(url, "popup", opts);
  }

  $(".ssb-icon").on("click", function (e) {
    const shareUrl = $(this).attr("href");
    if (!shareUrl.startsWith("mailto:")) {
      e.preventDefault();
      openShareUrl(shareUrl);
    }
  });
});
