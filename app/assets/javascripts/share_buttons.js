$(function () {
  function openShareUrl(url, initialWidth = 640, initialHeight = 480) {
    const width = Math.max(100, Math.min(screen.width, initialWidth));
    const height = Math.max(100, Math.min(screen.height, initialHeight));

    const left = screenLeft + ((outerWidth - width) / 2);
    const top = screenTop + ((outerHeight - height) / 2);
    const opts = `width=${width},height=${height},left=${left},top=${top},menubar=no,status=no,location=no`;

    window.open(url, "popup", opts);
  }

  $("[data-share-type='site']").on("click", function (e) {
    e.preventDefault();
    openShareUrl(this.href);
  });

  if (navigator.share) {
    $("[data-share-type='native']").prop("hidden", false).on("click", function () {
      navigator.share(Object.fromEntries(new URLSearchParams(this.hash.slice(1))));
    });
  }
});
