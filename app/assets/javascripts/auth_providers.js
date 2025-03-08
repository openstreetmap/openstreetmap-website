$(function () {
  // Attach referer to authentication buttons
  $(".auth_button").each(function () {
    const params = new URLSearchParams(this.search);
    params.set("referer", $("#referer").val());
    this.search = params.toString();
  });
});
