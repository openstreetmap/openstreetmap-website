$(function () {
  // Attach referer to authentication buttons
  $(".auth_button").each(function () {
    const params = new URLSearchParams(this.search);
    params.set("referer", $("#referer").val() || "");
    this.search = params.toString();
  });

  // Auto-click authentication button if autologin_provider query parameter is present
  const urlParams = new URLSearchParams(window.location.search);
  const autologinProvider = urlParams.get('autologin_provider');
  if (autologinProvider) {
    const providers = ['google', 'facebook', 'microsoft', 'github', 'wikipedia'];
    if (providers.includes(autologinProvider)) {
      $(`.auth_button_${autologinProvider}`).first().click();
    }
  }
});
