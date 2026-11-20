(function () {
  function beforeUnloadListener(event) {
    event.preventDefault();
  };

  function onChangedForm() {
    addEventListener("beforeunload", beforeUnloadListener);
    document.body.dataset.unsavedChanges = "true";
  };

  function onAllChangesSaved() {
    removeEventListener("beforeunload", beforeUnloadListener);
    delete document.body.dataset.unsavedChanges;
  };

  function formState(form) {
    return new URLSearchParams(new FormData(form)).toString();
  }

  $(document).on("turbo:load ready", function () {
    $("form[data-unsaved-changes-warning]").each(function () {
      const form = this;
      const initialState = formState(form);
      let warningEnabled = false;

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
