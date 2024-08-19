//= require src/jquery.uls.data
//= require src/jquery.uls.data.utils
//= require src/jquery.uls.lcd
//= require src/jquery.uls.languagefilter
//= require src/jquery.uls.core

$(document).ready(function () {
  if ($("head").data().user) {
    return;
  }

  function updateLanguage(language) {
    Cookies.set("_osm_locale", language, { secure: true, path: "/", samesite: "lax" });

    document.location.reload();
  }

  var languages = $.uls.data.getAutonyms();

  for (var code in languages) {
    if (!OSM.AVAILABLE_LOCALES.includes(code)) {
      delete languages[code];
    }
  }

  $(".language-change-trigger").click(e => e.preventDefault()).uls({
    onSelect: updateLanguage,
    languages: languages
  });
});
