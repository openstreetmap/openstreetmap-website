$(document).on("click", "#select_language_dialog [data-language-code]", function (e) {
  e.preventDefault();

  const code = $(this).data("language-code");
  const form = this.closest("form");

  if (form) {
    form.elements.language.value = code;
    form.submit();
  } else {
    OSM.cookies.set("_osm_locale", code);
    location.reload();
  }
});

// Prevent accidental Enter key submits inside the language dialog
$(document).on("keydown", "#select_language_dialog", function (e) {
  if (e.key === "Enter" || e.keyCode === 13) {
    // If the focused element is NOT inside a language option,
    // block the default form submission.
    if (!e.target.closest("[data-language-code]")) {
      e.preventDefault();
    }
  }
});
