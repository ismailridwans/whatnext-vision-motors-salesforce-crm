public with sharing class InventoryService {
    public static List<Vehicle__c> buildAvailabilityUpdates(List<Vehicle__c> vehicles) {
        List<Vehicle__c> updates = new List<Vehicle__c>();

        if (vehicles == null || vehicles.isEmpty()) {
            return updates;
        }

        for (Vehicle__c vehicleRecord : vehicles) {
            Vehicle__c updatedVehicle = new Vehicle__c(Id = vehicleRecord.Id);
            updatedVehicle.Is_Available__c = normalizeStock(vehicleRecord.Available_Stock__c) > 0;
            updatedVehicle.Last_Stock_Checked__c = System.now();
            updates.add(updatedVehicle);
        }

        return updates;
    }

    public static void refreshBulkOrderStatuses(Set<Id> vehicleIds) {
        if (vehicleIds == null || vehicleIds.isEmpty()) {
            return;
        }

        Map<Id, Vehicle__c> vehiclesById = new Map<Id, Vehicle__c>([
            SELECT Id, Available_Stock__c
            FROM Vehicle__c
            WHERE Id IN :vehicleIds
        ]);

        List<Customer_Order__c> ordersToUpdate = new List<Customer_Order__c>();

        for (Customer_Order__c orderRecord : [
            SELECT Id, Vehicle__c, Quantity__c, Order_Status__c, Is_Bulk_Order__c
            FROM Customer_Order__c
            WHERE Is_Bulk_Order__c = true
            AND Vehicle__c IN :vehicleIds
            AND Order_Status__c != 'Rejected'
        ]) {
            Vehicle__c vehicleRecord = vehiclesById.get(orderRecord.Vehicle__c);
            Decimal availableStock = vehicleRecord == null ? 0 : normalizeStock(vehicleRecord.Available_Stock__c);
            Decimal requestedQuantity = normalizeQuantity(orderRecord.Quantity__c);
            String expectedStatus = availableStock > 0 && availableStock >= requestedQuantity ? 'Confirmed' : 'Pending';

            if (orderRecord.Order_Status__c != expectedStatus) {
                ordersToUpdate.add(
                    new Customer_Order__c(
                        Id = orderRecord.Id,
                        Order_Status__c = expectedStatus
                    )
                );
            }
        }

        if (!ordersToUpdate.isEmpty()) {
            update ordersToUpdate;
        }
    }

    public static List<Vehicle__c> getLowStockVehicles(List<Vehicle__c> vehicles) {
        List<Vehicle__c> lowStockVehicles = new List<Vehicle__c>();

        if (vehicles == null || vehicles.isEmpty()) {
            return lowStockVehicles;
        }

        for (Vehicle__c vehicleRecord : vehicles) {
            Decimal availableStock = normalizeStock(vehicleRecord.Available_Stock__c);
            Decimal reorderThreshold = vehicleRecord.Reorder_Threshold__c == null
                ? 5
                : vehicleRecord.Reorder_Threshold__c;

            if (availableStock <= reorderThreshold) {
                lowStockVehicles.add(vehicleRecord);
            }
        }

        return lowStockVehicles;
    }

    private static Decimal normalizeQuantity(Decimal quantityValue) {
        return quantityValue == null || quantityValue <= 0 ? 1 : quantityValue;
    }

    private static Decimal normalizeStock(Decimal stockValue) {
        return stockValue == null ? 0 : stockValue;
    }
}

