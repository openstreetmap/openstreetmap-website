$(document).ready(function () {
  // Preserve location hash in referer
  if (window.location.hash) {
    $("#referer").val($("#referer").val() + window.location.hash);
  }
});
