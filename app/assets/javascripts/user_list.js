(function () {
  $(document).on("change", "#user_all", function () {
    $("#user_list input[type=checkbox]").prop("checked", $("#user_all").prop("checked"));
  });
}());
