/*
  Single Page Application Pagination

  1. Add navigation buttons:
  <%= render "shared/pagination_spa",
    :newer_key => "key_for_previous_page",
    :older_key => "key_for_next_page"
  %>

  2. Add a container, where the view will be rendered:
  <div id="container_page"></div>

  3. Add "/page" endpoint to the current route. PaginationMethods can be used to filter data.
*/

$(document).ready(() => {
  let afterInput, beforeInput;
  const nextButton = $("#button_next_page");
  const previousButton = $("#button_previous_page");
  const container = $("#container_page");

  function fetchIssues(queryParams) {
    const lastResult = container.html();
    container.html(`
      <div class="d-flex justify-content-center">
        <div class='spinner-border' role='status'>
          <span class='visually-hidden'>
            ${I18n.t("browse.start_rjs.loading")}
          </span>
        </div>
      </div>`);

    nextButton.hide();
    previousButton.hide();

    $.ajax({
      oauth: true,
      url:
        window.location.origin +
        window.location.pathname +
        "/page?" + queryParams,
      cache: false,
      success: (result) => {
        container.html(result);
        beforeInput = $("input[name='before']")[0];
        afterInput = $("input[name='after']")[0];

        nextButton.toggleClass("disabled", !beforeInput);
        previousButton.toggleClass("disabled", !afterInput);

        nextButton.show();
        previousButton.show();
      },
      error: () => {
        container.html(lastResult);

        nextButton.show();
        previousButton.show();
      }
    });
  }

  function getQueryParams(beforeInput, afterInput) {
    let url = new URL(window.location);

    url.searchParams.set("limit", url.searchParams.get("limit") || 50);

    if (beforeInput && beforeInput.value) {
      url.searchParams.set("before", beforeInput.value);
      url.searchParams.delete("after");
    } else if (afterInput && afterInput.value) {
      url.searchParams.set("after", afterInput.value);
      url.searchParams.delete("before");
    }

    history.pushState({}, "", url);

    return url.searchParams;
  }

  nextButton.click(() => {
    if (nextButton.hasClass("disabled")) {
      return;
    }

    fetchIssues(getQueryParams(
      beforeInput,
      null
    ));
  });

  previousButton.click(() => {
    if (previousButton.hasClass("disabled")) {
      return;
    }

    fetchIssues(getQueryParams(
      null,
      afterInput
    ));
  });

  window.addEventListener("popstate", () => {
    fetchIssues(this.location.search);
  });

  fetchIssues(getQueryParams(
    beforeInput,
    afterInput
  ));
});
