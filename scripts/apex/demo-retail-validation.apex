Vehicle__c outOfStockVehicle = [
    SELECT Id
    FROM Vehicle__c
    WHERE Name = 'Atlas SUV'
    LIMIT 1
];

try {
    insert new Customer_Order__c(
        Customer_Name__c = 'Validation Demo Customer',
        Customer_Email__c = 'validation.demo@example.com',
        Customer_Postal_Code__c = '600001',
        Customer_State__c = 'Tamil Nadu',
        Vehicle__c = outOfStockVehicle.Id,
        Quantity__c = 1,
        Is_Bulk_Order__c = false
    );
} catch (DmlException ex) {
    System.debug('Expected validation message: ' + ex.getMessage());
}

