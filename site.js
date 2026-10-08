const form = document.querySelector("#gallery-form");
const error = document.querySelector("#gallery-error");
const reserved = new Set(["api", "www"]);
form.addEventListener("submit", (event) => {
  event.preventDefault();
  const name = form.elements.photographer.value.trim().toLowerCase();
  if (
    !/^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$/.test(name) ||
    reserved.has(name)
  ) {
    error.textContent =
      "Enter your photographer’s Lumiere name, such as portraitstudio. “api” and “www” are service addresses.";
    error.hidden = false;
    form.elements.photographer.focus();
    return;
  }
  error.hidden = true;
  window.location.assign(`https://${name}.lumiere.host/`);
});
document.querySelector("#year").textContent = new Date().getFullYear();
