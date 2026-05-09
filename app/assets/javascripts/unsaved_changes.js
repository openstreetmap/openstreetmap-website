(function () {
  function beforeUnloadListener(event) {
    event.preventDefault();
    // Legacy support for older browsers.
    event.returnValue = true;
  };

  // A function that adds a `beforeunload` listener if there are unsaved changes.
  function onChangedForm() {
    addEventListener("beforeunload", beforeUnloadListener);
    document.body.dataset.unsavedChanges = "true";
  };

  // A function that removes the `beforeunload` listener when the page's unsaved changes are resolved.
  function onAllChangesSaved() {
    removeEventListener("beforeunload", beforeUnloadListener);
    delete document.body.dataset.unsavedChanges;
  };

  // Return current state of form, used to compare against later
  function formState(form) {
    return new URLSearchParams(new FormData(form)).toString();
  }

  $(document).on("turbo:load ready", function () {
    $("form[data-unsaved-changes-warning]").each(function () {
      // Get initial state of each form tagged with attribute
      const form = this;
      const initialState = formState(form);
      let warningEnabled = false;

      // Check if form has changed, and set flag for warning as appropriate
      function updateWarning() {
        const isChanged = (formState(form) !== initialState);

        if (isChanged && !warningEnabled) {
          onChangedForm();
          warningEnabled = true;
        } else if (!isChanged && warningEnabled) {
          onAllChangesSaved();
          warningEnabled = false;
        }
      }

      $(form).on("input change", updateWarning);
      $(form).on("submit", onAllChangesSaved);
    });
  });
}()
);
