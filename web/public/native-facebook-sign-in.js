// Submit Rails' CSRF-protected POST form so OmniAuth creates and validates OAuth state.
(() => {
  const form = document.getElementById("native-facebook-sign-in");
  if (form instanceof HTMLFormElement) form.requestSubmit();
})();
