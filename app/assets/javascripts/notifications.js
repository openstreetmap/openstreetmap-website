$(function () {
  const selectPageCheckbox = $("#select_page");
  const individualCheckboxes = $(".notification-mark-for-deletion");

  individualCheckboxes.on("click", function () {
    if (allInPageSelected()) {
      selectPageCheckbox.prop("checked", true);
      selectPageCheckbox.prop("indeterminate", false);
    } else if (anyInPageSelected()) {
      selectPageCheckbox.prop("checked", false);
      selectPageCheckbox.prop("indeterminate", true);
    } else {
      selectPageCheckbox.prop("checked", false);
      selectPageCheckbox.prop("indeterminate", false);
    }
  });

  selectPageCheckbox.on("click", function (evt) {
    if (evt.target.checked) {
      individualCheckboxes.prop("checked", true);
    } else {
      individualCheckboxes.prop("checked", false);
    }
  });

  function allInPageSelected() {
    return individualCheckboxes.get().every(el => el.checked);
  }

  function anyInPageSelected() {
    return individualCheckboxes.get().some(el => el.checked);
  }
});
