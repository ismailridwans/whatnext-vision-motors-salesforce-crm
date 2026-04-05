# Mentor Demo Runbook

## Goal

Show that the org supports customer ordering, nearest-dealer assignment, stock validation, bulk-order automation, and scheduled reminders.

## Recommended order

1. Open `docs/index.html` and use the interactive website to introduce the business problem, order simulator, and inventory recovery flow.
2. Open the WhatNext Vision Motors Lightning app.
3. Walk through the custom objects: Dealers, Vehicles, Customer Orders, Test Drives, and Service Requests.
4. Show the `Falcon EV` retail order and explain why it is `Confirmed`.
5. Show the `Atlas SUV` bulk order and explain why it is `Pending`.
6. Run `scripts/apex/demo-retail-validation.apex` to demonstrate the retail stock rule.
7. Edit `Atlas SUV` stock to a value above the pending order quantity.
8. Run `scripts/apex/run-inventory-batch.apex`.
9. Reopen the bulk order and show that it moved to `Confirmed`.
10. Open the upcoming test drive and explain the reminder process.

## Talking points

- Dealer assignment uses customer coordinates first, then postal code, then state.
- Retail orders are blocked if stock is unavailable.
- Bulk orders are allowed but stay in `Pending` until inventory recovers.
- Batch Apex keeps stock availability flags aligned with inventory.
- Scheduled Apex sends email reminders for test drives and supports nightly inventory processing.
