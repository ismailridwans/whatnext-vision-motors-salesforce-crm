global with sharing class VehicleInventoryBatch implements Database.Batchable<Vehicle__c>, Database.Stateful {
    private List<Vehicle__c> lowStockVehicles = new List<Vehicle__c>();

    global Database.QueryLocator start(Database.BatchableContext batchContext) {
        return Database.getQueryLocator([
            SELECT Id, Name, Available_Stock__c, Is_Available__c, Reorder_Threshold__c, Last_Stock_Checked__c
            FROM Vehicle__c
        ]);
    }

    global void execute(Database.BatchableContext batchContext, List<Vehicle__c> vehicles) {
        if (vehicles.isEmpty()) {
            return;
        }

        List<Vehicle__c> updates = InventoryService.buildAvailabilityUpdates(vehicles);
        if (!updates.isEmpty()) {
            update updates;
        }

        lowStockVehicles.addAll(InventoryService.getLowStockVehicles(vehicles));
        InventoryService.refreshBulkOrderStatuses(new Map<Id, Vehicle__c>(vehicles).keySet());
    }

    global void finish(Database.BatchableContext batchContext) {
        List<Vehicle__c> uniqueLowStockVehicles = deduplicateLowStockVehicles();
        if (!uniqueLowStockVehicles.isEmpty()) {
            EmailNotificationService.sendLowStockAlerts(uniqueLowStockVehicles);
        }
    }

    @TestVisible
    private List<Vehicle__c> deduplicateLowStockVehicles() {
        Map<Id, Vehicle__c> uniqueVehicles = new Map<Id, Vehicle__c>();
        for (Vehicle__c vehicleRecord : lowStockVehicles) {
            uniqueVehicles.put(vehicleRecord.Id, vehicleRecord);
        }
        return uniqueVehicles.values();
    }
}
