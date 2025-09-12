$(document).on("click", "#select_language_dialog [data-language-code]", function (e) {
  e.preventDefault();

  const code = $(this).data("language-code");
  const form = this.closest("form");

  if (form) {
    form.elements.language.value = code;
    form.submit();
  } else {
    Cookies.set("_osm_locale", code, { secure: true, path: "/", samesite: "lax" });
    location.reload();
  }
});
