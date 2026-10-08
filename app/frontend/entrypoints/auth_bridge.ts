const form = document.getElementById("facebook-signin");

if (form instanceof HTMLFormElement) {
  // Use the CSRF-protected POST form, just as a manual button click would.
  const redirectTimer = window.setTimeout(() => form.requestSubmit(), 600);
  form.addEventListener("submit", () => window.clearTimeout(redirectTimer), {
    once: true,
  });
}
