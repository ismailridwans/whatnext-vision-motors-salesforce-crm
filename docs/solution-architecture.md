# Solution Architecture

## Business objective

WhatNext Vision Motors needs a Salesforce implementation that improves customer ordering, prevents invalid vehicle orders, routes customers to the nearest dealer, and automates operational follow-up with Apex and scheduled processing.

## Domain model

### Dealer (`Dealer__c`)

- Stores dealer master data and routing coordinates.
- Used by order assignment and test-drive management.

### Vehicle (`Vehicle__c`)

- Stores vehicle catalogue details and stock availability.
- Batch Apex keeps `Is_Available__c` aligned with stock levels.

### Customer Order (`Customer_Order__c`)

- Stores customer purchase requests.
- Trigger logic validates stock and assigns the best dealer.
- Confirmed orders reserve stock automatically on the related vehicle.
- Bulk orders can stay in `Pending` until inventory improves.

### Test Drive (`Test_Drive__c`)

- Stores scheduled test drives.
- Scheduled Apex sends reminder emails before the appointment.

### Service Request (`Service_Request__c`)

- Stores after-sales support and service interactions.

## Automation map

### Trigger automation

- `CustomerOrderTrigger` routes customer orders to the nearest dealer.
- `CustomerOrderTrigger` blocks retail orders when requested stock is not available.
- `CustomerOrderTrigger` marks bulk orders as `Pending` when stock is not yet sufficient.
- `CustomerOrderTrigger` reserves or releases vehicle stock based on order status changes.
- `CustomerOrderTrigger` sends customer emails when order status changes to `Pending` or `Confirmed`.

### Batch and scheduled automation

- `VehicleInventoryBatch` refreshes stock availability flags.
- `VehicleInventoryBatch` re-evaluates bulk order statuses after each inventory scan.
- `VehicleInventoryBatch` sends a low-stock summary email to the running user.
- `TestDriveReminderScheduler` finds upcoming test drives and sends customer reminders.
- `VehicleInventoryScheduler` wraps the batch for nightly scheduling.

## Dealer assignment strategy

1. Use latitude and longitude when the customer order contains coordinates.
2. Fall back to exact postal-code match.
3. Fall back to state match.
4. Fall back to the first available dealer if no better match exists.

## Assumptions

- Dealer latitude and longitude are maintained in Salesforce.
- Customer coordinates can be captured from an Experience Cloud page, flow, or integration.
- Retail orders should be blocked if the requested quantity cannot be fulfilled immediately.
- Bulk orders may remain open and be revisited by the scheduled inventory process.

## Suggested presentation points

- Show the trigger framework and explain why it keeps logic modular.
- Show the batch job moving bulk orders from `Pending` to `Confirmed`.
- Show the reminder scheduler marking `Reminder_Sent__c` after email delivery.
- Show how the data model supports both sales and service use cases in one org.
