# Demo Scenarios

## Seeded records

- Dealers: Bengaluru Central Dealer, Chennai City Dealer, Mumbai EV Hub
- Vehicles: Falcon EV, Atlas SUV, Aurora Hybrid
- Orders: one confirmed retail order and one pending bulk order
- Test drives: one upcoming test drive for reminder automation
- Service requests: one service request for after-sales support tracking

## Mentor demo storyline

1. Open the WhatNext Vision Motors app.
2. Show the seeded dealers and vehicles.
3. Open the confirmed retail order and highlight the assigned dealer plus `Confirmed` status.
4. Open the pending bulk order and explain that the stock level forced it into `Pending`.
5. Run `scripts/apex/demo-retail-validation.apex` and show the out-of-stock validation message in the logs.
6. Increase `Atlas SUV` stock, run `scripts/apex/run-inventory-batch.apex`, then reopen the bulk order to show it changed to `Confirmed`.
7. Open the scheduled test drive and run the reminder scheduler or wait for the scheduled job window.
