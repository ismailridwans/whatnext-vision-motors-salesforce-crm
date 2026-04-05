Map<String, Dealer__c> dealersByName = new Map<String, Dealer__c>();
for (Dealer__c dealerRecord : [
    SELECT Id, Name
    FROM Dealer__c
    WHERE Name IN ('Bengaluru Central Dealer', 'Chennai City Dealer', 'Mumbai EV Hub')
]) {
    dealersByName.put(dealerRecord.Name, dealerRecord);
}

List<Dealer__c> dealersToInsert = new List<Dealer__c>();
if (!dealersByName.containsKey('Bengaluru Central Dealer')) {
    dealersToInsert.add(new Dealer__c(
        Name = 'Bengaluru Central Dealer',
        City__c = 'Bengaluru',
        State__c = 'Karnataka',
        Postal_Code__c = '560001',
        Latitude__c = 12.9716,
        Longitude__c = 77.5946,
        Dealer_Email__c = 'blr.dealer@example.com'
    ));
}
if (!dealersByName.containsKey('Chennai City Dealer')) {
    dealersToInsert.add(new Dealer__c(
        Name = 'Chennai City Dealer',
        City__c = 'Chennai',
        State__c = 'Tamil Nadu',
        Postal_Code__c = '600001',
        Latitude__c = 13.0827,
        Longitude__c = 80.2707,
        Dealer_Email__c = 'chn.dealer@example.com'
    ));
}
if (!dealersByName.containsKey('Mumbai EV Hub')) {
    dealersToInsert.add(new Dealer__c(
        Name = 'Mumbai EV Hub',
        City__c = 'Mumbai',
        State__c = 'Maharashtra',
        Postal_Code__c = '400001',
        Latitude__c = 19.0760,
        Longitude__c = 72.8777,
        Dealer_Email__c = 'mum.dealer@example.com'
    ));
}
if (!dealersToInsert.isEmpty()) {
    insert dealersToInsert;
}

Map<String, Vehicle__c> vehiclesByName = new Map<String, Vehicle__c>();
for (Vehicle__c vehicleRecord : [
    SELECT Id, Name
    FROM Vehicle__c
    WHERE Name IN ('Falcon EV', 'Atlas SUV', 'Aurora Hybrid')
]) {
    vehiclesByName.put(vehicleRecord.Name, vehicleRecord);
}

List<Vehicle__c> vehiclesToInsert = new List<Vehicle__c>();
if (!vehiclesByName.containsKey('Falcon EV')) {
    vehiclesToInsert.add(new Vehicle__c(
        Name = 'Falcon EV',
        Model_Code__c = 'FAL-EV',
        Vehicle_Type__c = 'EV',
        Base_Price__c = 3200000,
        Available_Stock__c = 5,
        Reorder_Threshold__c = 2
    ));
}
if (!vehiclesByName.containsKey('Atlas SUV')) {
    vehiclesToInsert.add(new Vehicle__c(
        Name = 'Atlas SUV',
        Model_Code__c = 'ATL-SUV',
        Vehicle_Type__c = 'SUV',
        Base_Price__c = 4100000,
        Available_Stock__c = 0,
        Reorder_Threshold__c = 2
    ));
}
if (!vehiclesByName.containsKey('Aurora Hybrid')) {
    vehiclesToInsert.add(new Vehicle__c(
        Name = 'Aurora Hybrid',
        Model_Code__c = 'AUR-HYB',
        Vehicle_Type__c = 'Hybrid',
        Base_Price__c = 3600000,
        Available_Stock__c = 7,
        Reorder_Threshold__c = 3
    ));
}
if (!vehiclesToInsert.isEmpty()) {
    insert vehiclesToInsert;
}

dealersByName = new Map<String, Dealer__c>([
    SELECT Id, Name
    FROM Dealer__c
    WHERE Name IN ('Bengaluru Central Dealer', 'Chennai City Dealer', 'Mumbai EV Hub')
]);
Map<String, Vehicle__c> refreshedVehiclesByName = new Map<String, Vehicle__c>([
    SELECT Id, Name
    FROM Vehicle__c
    WHERE Name IN ('Falcon EV', 'Atlas SUV', 'Aurora Hybrid')
]);

if ([SELECT COUNT() FROM Customer_Order__c WHERE Customer_Email__c = 'asha@example.com'] == 0) {
    insert new Customer_Order__c(
        Customer_Name__c = 'Asha Raman',
        Customer_Email__c = 'asha@example.com',
        Customer_Postal_Code__c = '560001',
        Customer_State__c = 'Karnataka',
        Customer_Latitude__c = 12.9716,
        Customer_Longitude__c = 77.5946,
        Vehicle__c = refreshedVehiclesByName.get('Falcon EV').Id,
        Quantity__c = 1,
        Requested_Delivery_Date__c = Date.today().addDays(7)
    );
}

if ([SELECT COUNT() FROM Customer_Order__c WHERE Customer_Email__c = 'fleetbuyer@example.com'] == 0) {
    insert new Customer_Order__c(
        Customer_Name__c = 'Fleet Buyer',
        Customer_Email__c = 'fleetbuyer@example.com',
        Customer_Postal_Code__c = '600001',
        Customer_State__c = 'Tamil Nadu',
        Vehicle__c = refreshedVehiclesByName.get('Atlas SUV').Id,
        Quantity__c = 3,
        Is_Bulk_Order__c = true,
        Requested_Delivery_Date__c = Date.today().addDays(14)
    );
}

if ([SELECT COUNT() FROM Test_Drive__c WHERE Customer_Email__c = 'neha@example.com'] == 0) {
    insert new Test_Drive__c(
        Customer_Name__c = 'Neha Kapoor',
        Customer_Email__c = 'neha@example.com',
        Vehicle__c = refreshedVehiclesByName.get('Aurora Hybrid').Id,
        Dealer__c = dealersByName.get('Mumbai EV Hub').Id,
        Scheduled_Date_Time__c = System.now().addHours(6),
        Status__c = 'Scheduled'
    );
}

if ([SELECT COUNT() FROM Service_Request__c WHERE Customer_Email__c = 'service.customer@example.com'] == 0) {
    insert new Service_Request__c(
        Customer_Name__c = 'Service Customer',
        Customer_Email__c = 'service.customer@example.com',
        Vehicle__c = refreshedVehiclesByName.get('Aurora Hybrid').Id,
        Dealer__c = dealersByName.get('Mumbai EV Hub').Id,
        Preferred_Service_Date__c = Date.today().addDays(10),
        Request_Status__c = 'New',
        Description__c = 'Customer requested first-service inspection and battery health check.'
    );
}

System.debug('WhatNext Vision Motors demo data is ready.');

