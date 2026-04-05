# Project TODO

## Completed in this repository

- Salesforce DX structure for the WhatNext Vision Motors app
- Custom objects for dealers, vehicles, customer orders, test drives, and service requests
- Apex trigger framework for dealer assignment, stock validation, stock reservation, and order status handling
- Batch Apex and schedulers for inventory refresh and test-drive reminders
- Permission set, layouts, demo scripts, and deployment runbooks
- Interactive presentation website in `docs/index.html`

## Ready for deployment

- Deploy metadata with the commands in `docs/deployment-runbook.md`
- Assign `WhatNext_Vision_Motors_Admin`
- Seed records with `scripts/apex/seed-demo-data.apex`
- Run validation and batch demo scripts from `scripts/apex`

## Remaining external actions

- Deploy the project into a real Salesforce org because the local environment here does not include the Salesforce CLI
- Record a short demo video for SkillWallet submission
- Replace the placeholder demo link in `README.md` and `docs/submission-links.md`
- Optionally publish the interactive site with GitHub Pages
- Rotate the GitHub token that was shared in chat

## Suggested next polish

- Add a real org demo video URL after deployment
- Add screenshots from the live Salesforce app into the website or README
- If needed for evaluation, create flows or dashboards on top of the current Apex-backed solution

