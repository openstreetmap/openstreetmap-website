$(document).ready(function () {
  $("#available_languages_menu").prop("hidden", false);
  $("#user_languages, #available_languages").on("input", updateButtons);
  updateButtons();

  $("#add_preferred_language").click(function () {
    var preferredLanguagesValue = $("#user_languages").val().trim();
    var selectedLanguage = $("#available_languages").val();
    $("#user_languages").val(selectedLanguage + " " + preferredLanguagesValue);
    updateButtons();
    $("#remove_preferred_language").trigger("focus");
  });

  $("#remove_preferred_language").click(function () {
    var preferredLanguages = $("#user_languages").val().trim().split(/\s+/);
    var selectedLanguage = $("#available_languages").val();
    var updatedPreferredLanguages = preferredLanguages.filter(function (language) {
      return language !== selectedLanguage;
    });
    $("#user_languages").val(updatedPreferredLanguages.join(" "));
    updateButtons();
    $("#add_preferred_language").trigger("focus");
  });

  function updateButtons() {
    var preferredLanguages = $("#user_languages").val().trim().split(/\s+/);
    var selectedLanguage = $("#available_languages").val();
    var languageAlreadyAdded = preferredLanguages.includes(selectedLanguage);
    $("#add_preferred_language").prop("hidden", languageAlreadyAdded);
    $("#remove_preferred_language").prop("hidden", !languageAlreadyAdded);
  }
});
