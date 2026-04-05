for (CronTrigger existingJob : [
    SELECT Id, CronJobDetail.Name
    FROM CronTrigger
    WHERE CronJobDetail.Name IN ('Nightly Inventory Refresh', 'Hourly Test Drive Reminders')
]) {
    System.abortJob(existingJob.Id);
}

System.schedule('Nightly Inventory Refresh', '0 0 1 * * ?', new VehicleInventoryScheduler());
System.schedule('Hourly Test Drive Reminders', '0 0 * * * ?', new TestDriveReminderScheduler());
