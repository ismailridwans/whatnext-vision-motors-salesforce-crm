@IsTest
private class VehicleInventoryBatchTest {
    @testSetup
    static void setupData() {
        Dealer__c dealerRecord = new Dealer__c(
            Name = 'Hyderabad Dealer',
            City__c = 'Hyderabad',
            State__c = 'Telangana',
            Postal_Code__c = '500001',
            Latitude__c = 17.3850,
            Longitude__c = 78.4867,
            Dealer_Email__c = 'hyd.dealer@example.com'
        );
        insert dealerRecord;

        Vehicle__c vehicleRecord = new Vehicle__c(
            Name = 'RoadRunner EV',
            Model_Code__c = 'RR-EV',
            Vehicle_Type__c = 'EV',
            Base_Price__c = 2800000,
            Available_Stock__c = 0,
            Reorder_Threshold__c = 2
        );
        insert vehicleRecord;

        insert new Customer_Order__c(
            Customer_Name__c = 'City Fleet',
            Customer_Email__c = 'cityfleet@example.com',
            Customer_Postal_Code__c = '500001',
            Customer_State__c = 'Telangana',
            Vehicle__c = vehicleRecord.Id,
            Quantity__c = 4,
            Is_Bulk_Order__c = true
        );
    }

    @IsTest
    static void batchRefreshesAvailabilityAndConfirmsBulkOrdersAfterRestock() {
        Vehicle__c vehicleRecord = [SELECT Id FROM Vehicle__c WHERE Name = 'RoadRunner EV' LIMIT 1];
        Customer_Order__c orderRecord = [
            SELECT Id, Order_Status__c
            FROM Customer_Order__c
            LIMIT 1
        ];

        System.assertEquals('Pending', orderRecord.Order_Status__c);

        update new Vehicle__c(
            Id = vehicleRecord.Id,
            Available_Stock__c = 10,
            Reorder_Threshold__c = 2
        );

        Test.startTest();
        Database.executeBatch(new VehicleInventoryBatch(), 50);
        Test.stopTest();

        Vehicle__c refreshedVehicle = [
            SELECT Available_Stock__c, Is_Available__c, Last_Stock_Checked__c
            FROM Vehicle__c
            WHERE Id = :vehicleRecord.Id
        ];
        Customer_Order__c refreshedOrder = [
            SELECT Order_Status__c
            FROM Customer_Order__c
            WHERE Id = :orderRecord.Id
        ];

        System.assertEquals(6, refreshedVehicle.Available_Stock__c);
        System.assertEquals(true, refreshedVehicle.Is_Available__c);
        System.assertNotEquals(null, refreshedVehicle.Last_Stock_Checked__c);
        System.assertEquals('Confirmed', refreshedOrder.Order_Status__c);
    }
}
