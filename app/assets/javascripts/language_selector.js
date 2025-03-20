$(document).on("change", ".language-change-trigger", function () {
  Cookies.set("_osm_locale", this.value, { secure: true, path: "/", samesite: "lax" });
  document.location.reload();
});
