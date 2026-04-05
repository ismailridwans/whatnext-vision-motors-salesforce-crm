@IsTest
private class CustomerOrderTriggerHandlerTest {
    @testSetup
    static void setupData() {
        insert new List<Dealer__c>{
            new Dealer__c(
                Name = 'Bengaluru Central Dealer',
                City__c = 'Bengaluru',
                State__c = 'Karnataka',
                Postal_Code__c = '560001',
                Latitude__c = 12.9716,
                Longitude__c = 77.5946,
                Dealer_Email__c = 'blr.dealer@example.com'
            ),
            new Dealer__c(
                Name = 'Chennai City Dealer',
                City__c = 'Chennai',
                State__c = 'Tamil Nadu',
                Postal_Code__c = '600001',
                Latitude__c = 13.0827,
                Longitude__c = 80.2707,
                Dealer_Email__c = 'chn.dealer@example.com'
            )
        };

        insert new List<Vehicle__c>{
            new Vehicle__c(
                Name = 'Falcon EV',
                Model_Code__c = 'FAL-EV',
                Vehicle_Type__c = 'EV',
                Base_Price__c = 3200000,
                Available_Stock__c = 5,
                Reorder_Threshold__c = 2
            ),
            new Vehicle__c(
                Name = 'Atlas SUV',
                Model_Code__c = 'ATL-SUV',
                Vehicle_Type__c = 'SUV',
                Base_Price__c = 4100000,
                Available_Stock__c = 0,
                Reorder_Threshold__c = 2
            )
        };
    }

    @IsTest
    static void assignsNearestDealerAndConfirmsAvailableOrder() {
        Vehicle__c vehicleRecord = [SELECT Id FROM Vehicle__c WHERE Name = 'Falcon EV' LIMIT 1];

        Customer_Order__c orderRecord = new Customer_Order__c(
            Customer_Name__c = 'Asha Raman',
            Customer_Email__c = 'asha@example.com',
            Customer_Postal_Code__c = '560001',
            Customer_State__c = 'Karnataka',
            Customer_Latitude__c = 12.9716,
            Customer_Longitude__c = 77.5946,
            Vehicle__c = vehicleRecord.Id,
            Quantity__c = 1
        );

        Test.startTest();
        insert orderRecord;
        Test.stopTest();

        Customer_Order__c insertedOrder = [
            SELECT Dealer__r.Name, Order_Status__c
            FROM Customer_Order__c
            WHERE Id = :orderRecord.Id
        ];

        System.assertEquals('Confirmed', insertedOrder.Order_Status__c);
        System.assertEquals('Bengaluru Central Dealer', insertedOrder.Dealer__r.Name);
    }

    @IsTest
    static void blocksRetailOrdersWhenInventoryIsUnavailable() {
        Vehicle__c vehicleRecord = [SELECT Id FROM Vehicle__c WHERE Name = 'Atlas SUV' LIMIT 1];

        Customer_Order__c orderRecord = new Customer_Order__c(
            Customer_Name__c = 'Rahul Menon',
            Customer_Email__c = 'rahul@example.com',
            Customer_Postal_Code__c = '600001',
            Customer_State__c = 'Tamil Nadu',
            Vehicle__c = vehicleRecord.Id,
            Quantity__c = 1,
            Is_Bulk_Order__c = false
        );

        Test.startTest();
        try {
            insert orderRecord;
            System.assert(false, 'A retail order should fail when the vehicle is out of stock.');
        } catch (DmlException ex) {
            System.assert(ex.getMessage().contains('out of stock'));
        }
        Test.stopTest();
    }

    @IsTest
    static void marksBulkOrdersPendingWhenInventoryIsLow() {
        Vehicle__c vehicleRecord = [SELECT Id FROM Vehicle__c WHERE Name = 'Atlas SUV' LIMIT 1];

        Customer_Order__c orderRecord = new Customer_Order__c(
            Customer_Name__c = 'Fleet Buyer',
            Customer_Email__c = 'fleet@example.com',
            Customer_Postal_Code__c = '560001',
            Customer_State__c = 'Karnataka',
            Vehicle__c = vehicleRecord.Id,
            Quantity__c = 3,
            Is_Bulk_Order__c = true
        );

        insert orderRecord;

        Customer_Order__c insertedOrder = [
            SELECT Order_Status__c, Dealer__c
            FROM Customer_Order__c
            WHERE Id = :orderRecord.Id
        ];

        System.assertEquals('Pending', insertedOrder.Order_Status__c);
        System.assertNotEquals(null, insertedOrder.Dealer__c);
    }
}

