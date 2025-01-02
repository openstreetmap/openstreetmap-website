$(document).ready(function () {
  const tooltipFn = function () {
    const toolitps = $("[data-bs-toggle='tooltip']");
    toolitps.tooltip();

    $(this).on("turbo:click.tooltip turbo:submit-start.tooltip", function ({ detail }) {
      const pathname =
        (detail.url && new URL(detail.url).pathname) ||
        (detail.formSubmission && detail.formSubmission.fetchRequest.url.pathname);
      toolitps.tooltip("dispose");
      if (pathname === window.location.pathname) {
        $(this).off("turbo:click.tooltip turbo:submit-start.tooltip");
      } else {
        $(this).off(".tooltip");
      }
    });
  };

  tooltipFn();
  $(document).on("turbo:load.tooltip", tooltipFn);
});
