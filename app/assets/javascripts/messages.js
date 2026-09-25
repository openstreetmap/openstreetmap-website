$(function () {
  $(".messages-table .destroy-message").on("turbo:submit-end", function (event) {
    if (event.detail.success) {
      event.target.dataset.isDestroyed = true;
    }
  });

  $(".messages-table tbody tr").on("turbo:before-morph-element", function (event) {
    if ($(event.target).find("[data-is-destroyed]").length > 0) {
      event.preventDefault(); // NB: prevent Turbo from morhping/removing this element
      $(event.target).fadeOut(800, "linear", function () {
        $(this).remove();
      });
    }
  });
});
