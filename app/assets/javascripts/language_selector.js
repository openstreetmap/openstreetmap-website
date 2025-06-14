$(document).on("click", "#language-selector .dropdown-menu button", function () {
  Cookies.set("_osm_locale", $(this).data("language"), { secure: true, path: "/", samesite: "lax" });
  document.location.reload();
});
