# Lumiere marketing site

Static, responsive site for the Lumiere multi-photographer platform. No Rails,
Ruby, JavaScript build, or Jekyll processing is required. The gallery finder
opens the entered photographer's subdomain; it is not a public directory.

GitHub Pages publishes the root of `gh-pages` in `lwm-luminx/hedonism_bot`.
`CNAME` preserves `lumiere.host`. HTTPS enforcement is enabled in Pages settings.
The canonical domain and sitemap both use HTTPS. Photography is served by
Unsplash; the brand mark, CSS, and script are local assets.

Preview with `python3 -m http.server 4178 --directory marketing`.
To publish, clone the existing `gh-pages` branch into a separate directory,
copy `index.html`, `styles.css`, `site.js`, `assets/`, `robots.txt`, `sitemap.xml`,
`CNAME`, and `.nojekyll` from here into its root, commit, and push. Do not copy
application files or this README into the published root. Verify the Pages
workflow succeeds and `https://lumiere.host/` returns the new page.
