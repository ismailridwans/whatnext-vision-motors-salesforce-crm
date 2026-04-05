# Deployment Runbook

## 1. Authenticate to the target org

```bash
sf org login web --alias whatnext-dev
```

## 2. Deploy the metadata

```bash
sf project deploy start --source-dir force-app --target-org whatnext-dev
```

## 3. Assign the permission set

```bash
sf org assign permset --name WhatNext_Vision_Motors_Admin --target-org whatnext-dev
```

## 4. Run Apex tests

```bash
sf apex run test --test-level RunLocalTests --target-org whatnext-dev --code-coverage
```

## 5. Seed the demo data

```bash
sf apex run --file scripts/apex/seed-demo-data.apex --target-org whatnext-dev
```

## 6. Schedule background jobs

```bash
sf apex run --file scripts/apex/schedule-jobs.apex --target-org whatnext-dev
```

## Optional demo commands

```bash
sf apex run --file scripts/apex/demo-retail-validation.apex --target-org whatnext-dev
sf apex run --file scripts/apex/run-inventory-batch.apex --target-org whatnext-dev
```

