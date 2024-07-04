(function () {
  function addTogglePasswordEventListener(buttonId, passwordFieldId) {
    const toggleButton = document.getElementById(buttonId);
    const passwordField = document.getElementById(passwordFieldId);

    toggleButton.addEventListener("click", function () {
      const eyeIcon = toggleButton.querySelector("img");
      const isPasswordFieldVisible = passwordField.type === "text";

      // toggle visibility
      passwordField.type = isPasswordFieldVisible ? "password" : "text";

      // toggle icons
      eyeIcon.classList.toggle("d-none");
      eyeIcon.nextElementSibling.classList.toggle("d-none");
    });
  }

  // attach to global window object
  window.addTogglePasswordEventListener = addTogglePasswordEventListener;
}());
