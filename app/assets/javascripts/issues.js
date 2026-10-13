$(document).ready(function () {
  $("[data-report-controls]").each(function () {
    $(this).on("click", "input", function () {
      toggleReports(this.value, this.checked);
    });
  });

  function toggleReports(category, display) {
    $("[data-report]")
      .has("[data-category=" + category + "]")
      .next("hr").addBack()
      .toggle(display);
  }
});
