$(document).ready(function () {
  let beforeInput;

  function fetchIssues() {
    const data = {
      limit: 50
    };

    if (beforeInput) {
      data.before = beforeInput.value;
      beforeInput.remove();
    }

    $.ajax({
      oauth: true,
      url:
        window.location.origin +
        window.location.pathname +
        "/page" +
        window.location.search,
      data,
      cache: false
    }).done(function (result) {
      $("#reports_table").append($(result));
      beforeInput = $("input[name='before']")[0];

      if (!beforeInput) {
        $("#reports_loading").remove();
      }
    });
  }

  let options = {
    root: null,
    threshold: 0.1
  };

  function handleIntersect(entries) {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        fetchIssues();
      }
    });
  }

  const observer = new IntersectionObserver(handleIntersect, options);
  observer.observe($("#reports_loading")[0]);
});
