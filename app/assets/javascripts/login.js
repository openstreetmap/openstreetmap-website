$(function () {
  // Preserve location hash in referer
  if (location.hash) {
    $("#referer").val($("#referer").val() + location.hash);
  }
});
