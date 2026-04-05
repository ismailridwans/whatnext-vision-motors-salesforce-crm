# WhatNext Vision Motors

Salesforce CRM implementation for the SkillWallet group project brief. This repository models vehicle inventory, dealer management, customer ordering, test drives, and service requests for an automotive business.

## Solution highlights

- Auto-assigns customer orders to the nearest dealer by latitude/longitude, with postal-code and state fallback logic.
- Prevents retail orders when a vehicle is out of stock.
- Marks bulk orders as `Pending` until inventory is replenished, then confirms them through batch processing.
- Sends scheduled test-drive reminder emails.
- Monitors low-stock vehicles and sends notification emails after each inventory batch run.

## Repo links for SkillWallet submission

- Demo link: add your recorded demo URL here
- GitHub link: https://github.com/ismailridwans/whatnext-vision-motors-salesforce-crm

## Project structure

- `force-app/main/default/objects`: custom objects and fields
- `force-app/main/default/classes`: Apex services, handlers, schedulers, and tests
- `force-app/main/default/triggers`: trigger entry points
- `docs/solution-architecture.md`: solution architecture and business mapping
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

## Demo flow

1. Create a few dealers with coordinates and postal codes.
2. Create vehicles with different stock levels.
3. Insert a retail order for an in-stock vehicle and show auto-assignment.
4. Insert a retail order for an out-of-stock vehicle and show the validation error.
5. Insert a bulk order for a low-stock vehicle and show the `Pending` status.
6. Run the inventory batch, replenish stock, and show the bulk order move to `Confirmed`.
7. Create a scheduled test drive and run the reminder scheduler.
