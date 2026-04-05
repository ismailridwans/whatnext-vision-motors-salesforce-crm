global with sharing class TestDriveReminderScheduler implements Schedulable {
    global void execute(SchedulableContext scheduledContext) {
        Datetime windowStart = System.now();
        Datetime windowEnd = System.now().addHours(24);

        List<Test_Drive__c> upcomingTestDrives = [
            SELECT Id, Customer_Name__c, Customer_Email__c, Scheduled_Date_Time__c,
                Reminder_Sent__c, Status__c, Vehicle__r.Name, Dealer__r.Name
            FROM Test_Drive__c
            WHERE Reminder_Sent__c = false
            AND Status__c = 'Scheduled'
            AND Scheduled_Date_Time__c >= :windowStart
            AND Scheduled_Date_Time__c <= :windowEnd
        ];

        if (upcomingTestDrives.isEmpty()) {
            return;
        }

        EmailNotificationService.sendTestDriveReminders(upcomingTestDrives);

        List<Test_Drive__c> updates = new List<Test_Drive__c>();
        for (Test_Drive__c testDriveRecord : upcomingTestDrives) {
            updates.add(new Test_Drive__c(Id = testDriveRecord.Id, Reminder_Sent__c = true));
        }

        update updates;
    }
}

