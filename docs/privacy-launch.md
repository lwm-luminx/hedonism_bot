# Privacy policy publication

The public routes are `/privacy` and `/data-deletion`; `/privacy.html` and `/data-deletion.html` also work. `LegalController` renders static Rails views without the application layout, a gallery lookup, JavaScript, or a Facebook login. The sign-in screen links to both.

Before publication:

- Replace `[PRIVACY CONTACT EMAIL]` in both pages with a monitored mailbox and remove the draft notices after reviewing the policy. Confirm that Lumière Archive / Hedonism Bot matches the Facebook app's display name.
- Confirm actual provider deployments, international processing locations, retention and backup lifecycles, and the statements about advertising and model training. The code does not establish company-wide practices or fixed retention periods.
- Establish and exercise the manual deletion procedure, including Facebook profile JSON and tokens, sessions, administrator memberships, photo originals/previews, metadata, captions, face crops, embeddings, group associations, queues, and storage/archive copies. Check schema dependencies before deleting accounts. Account deletion alone does not locate photos depicting that person.
- Review applicable consent and retention requirements for facial/biometric processing before enabling it; this privacy notice does not itself collect consent.
- Deploy and verify both URLs return HTTP 200 over HTTPS without authentication. These pages are served by Rails rather than the public file server, avoiding its one-year static-file cache lifetime.
- Enter `https://YOUR_APP_HOST/privacy.html` in Meta's Privacy Policy URL field and `https://YOUR_APP_HOST/data-deletion.html` as the data deletion instructions URL. The latter is an instructions page, not a signed-request callback endpoint.

References to check at submission time:

- https://developers.facebook.com/terms/
- https://developers.facebook.com/docs/development/create-an-app/app-dashboard/data-deletion-callback/

Meta's primary pages could not be fetched during drafting (access error / HTTP 429), so current submission requirements still need to be checked in the app dashboard. No deployment or Meta dashboard configuration was performed.
