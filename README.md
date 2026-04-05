# WhatNext Vision Motors

Salesforce CRM implementation for the SkillWallet group project brief. This repository models vehicle inventory, dealer management, customer ordering, test drives, and service requests for an automotive business.

## Solution highlights

- Auto-assigns customer orders to the nearest dealer by latitude/longitude, with postal-code and state fallback logic.
- Prevents retail orders when a vehicle is out of stock.
- Reserves stock automatically when an order is confirmed so inventory stays accurate.
- Marks bulk orders as `Pending` until inventory is replenished, then confirms them through batch processing.
- Sends scheduled test-drive reminder emails.
- Sends customer-facing order status emails when orders become `Pending` or `Confirmed`.
- Monitors low-stock vehicles and sends notification emails after each inventory batch run.

## Repo links for SkillWallet submission

- Demo link: add your recorded demo URL here
- GitHub link: https://github.com/ismailridwans/whatnext-vision-motors-salesforce-crm
- Interactive website: open `docs/index.html` locally or publish the `docs/` folder with GitHub Pages

## Project structure

- `force-app/main/default/objects`: custom objects and fields
- `force-app/main/default/classes`: Apex services, handlers, schedulers, and tests
- `force-app/main/default/triggers`: trigger entry points
- `force-app/main/default/permissionsets`: access package for the demo org
- `force-app/main/default/layouts`: page layouts for the custom objects
- `scripts/apex`: anonymous Apex scripts for seeding data and running demos
- `docs/index.html`: interactive website for project presentation and mentor walkthrough
- `docs/solution-architecture.md`: solution architecture and business mapping
- `docs/project-todo.md`: tracked completion list and remaining external actions
- `docs/github-pages-runbook.md`: steps to publish the site with GitHub Pages
- `docs/submission-links.md`: simple checklist for the project portal

## Deployment

1. Authenticate to a Salesforce org or scratch org.
2. Deploy metadata:

```bash
sf project deploy start --source-dir force-app
```

3. Run Apex tests:

```bash
sf apex run test --test-level RunLocalTests --code-coverage
```

4. Schedule the jobs after deployment:

```apex
System.schedule('Nightly Inventory Refresh', '0 0 1 * * ?', new VehicleInventoryScheduler());
System.schedule('Hourly Test Drive Reminders', '0 0 * * * ?', new TestDriveReminderScheduler());
```

5. Assign the permission set:

```bash
sf org assign permset --name WhatNext_Vision_Motors_Admin
```

6. Seed demo data:

```bash
sf apex run --file scripts/apex/seed-demo-data.apex
```

7. Optional demo helpers:

```bash
sf apex run --file scripts/apex/demo-retail-validation.apex
sf apex run --file scripts/apex/run-inventory-batch.apex
```

## Demo flow

1. Create a few dealers with coordinates and postal codes.
2. Create vehicles with different stock levels.
3. Insert a retail order for an in-stock vehicle and show auto-assignment.
4. Insert a retail order for an out-of-stock vehicle and show the validation error.
5. Insert a bulk order for a low-stock vehicle and show the `Pending` status.
6. Run the inventory batch, replenish stock, and show the bulk order move to `Confirmed`.
7. Create a scheduled test drive and run the reminder scheduler.

Detailed setup and presentation notes are in `docs/deployment-runbook.md`, `docs/mentor-demo-runbook.md`, `docs/project-todo.md`, and `docs/github-pages-runbook.md`.
