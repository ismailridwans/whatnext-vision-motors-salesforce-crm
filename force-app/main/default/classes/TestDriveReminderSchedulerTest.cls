@IsTest
private class TestDriveReminderSchedulerTest {
    @testSetup
    static void setupData() {
        Dealer__c dealerRecord = new Dealer__c(
            Name = 'Mumbai Dealer',
            City__c = 'Mumbai',
            State__c = 'Maharashtra',
            Postal_Code__c = '400001',
            Latitude__c = 19.0760,
            Longitude__c = 72.8777,
            Dealer_Email__c = 'mum.dealer@example.com'
        );
        insert dealerRecord;

        Vehicle__c vehicleRecord = new Vehicle__c(
            Name = 'Aurora Hybrid',
            Model_Code__c = 'AUR-HYB',
            Vehicle_Type__c = 'Hybrid',
            Base_Price__c = 3600000,
            Available_Stock__c = 7,
            Reorder_Threshold__c = 2
        );
        insert vehicleRecord;

        insert new Test_Drive__c(
            Customer_Name__c = 'Neha Kapoor',
            Customer_Email__c = 'neha@example.com',
            Vehicle__c = vehicleRecord.Id,
            Dealer__c = dealerRecord.Id,
            Scheduled_Date_Time__c = System.now().addHours(6),
            Status__c = 'Scheduled',
            Reminder_Sent__c = false
        );
    }

    @IsTest
    static void schedulerMarksUpcomingTestDrivesAsReminded() {
        Test.startTest();
        System.schedule(
            'Test Drive Reminder Job',
            '0 0 6 1 1 ? 2099',
            new TestDriveReminderScheduler()
        );
        Test.stopTest();

        Test_Drive__c updatedTestDrive = [
            SELECT Reminder_Sent__c
            FROM Test_Drive__c
            LIMIT 1
        ];

        System.assertEquals(true, updatedTestDrive.Reminder_Sent__c);
    }
}

