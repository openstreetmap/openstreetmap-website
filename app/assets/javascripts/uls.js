//= require src/jquery.uls.data
//= require src/jquery.uls.data.utils
//= require src/jquery.uls.lcd
//= require src/jquery.uls.languagefilter
//= require src/jquery.uls.core

$(document).ready(function () {
  function updateLanguage(language) {
    Cookies.set("_osm_locale", language, { secure: true, path: "/", samesite: "lax" });

    document.location.reload();
  }

  const languages = $.uls.data.getAutonyms();

  for (const code in languages) {
    if (!OSM.AVAILABLE_LOCALES.includes(code)) {
      delete languages[code];
    }
  }

  $(".uls-trigger").uls({
    onSelect: updateLanguage,
    languages: languages
  });

  const application_data = $("head").data();

  $(".uls-trigger").text(Cookies.get("_osm_locale") || application_data.locale);
});
