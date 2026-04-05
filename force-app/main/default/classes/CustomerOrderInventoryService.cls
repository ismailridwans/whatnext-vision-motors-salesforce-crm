public with sharing class CustomerOrderInventoryService {
    public static void allocateInventory(List<Customer_Order__c> orders, Map<Id, Customer_Order__c> oldMap) {
        if (orders == null || orders.isEmpty()) {
            return;
        }

        Set<Id> vehicleIds = new Set<Id>();
        Map<Id, Decimal> priorCommittedByVehicle = new Map<Id, Decimal>();

        for (Customer_Order__c orderRecord : orders) {
            if (orderRecord.Vehicle__c != null) {
                vehicleIds.add(orderRecord.Vehicle__c);
            }

            if (oldMap != null && oldMap.containsKey(orderRecord.Id)) {
                Customer_Order__c oldOrder = oldMap.get(orderRecord.Id);
                Decimal previouslyCommitted = getCommittedQuantity(oldOrder);
                if (previouslyCommitted > 0 && oldOrder.Vehicle__c != null) {
                    vehicleIds.add(oldOrder.Vehicle__c);
                    accumulate(priorCommittedByVehicle, oldOrder.Vehicle__c, previouslyCommitted);
                }
            }
        }

        if (vehicleIds.isEmpty()) {
            for (Customer_Order__c orderRecord : orders) {
                orderRecord.addError('Select a vehicle before submitting the order.');
            }
            return;
        }

        Map<Id, Vehicle__c> vehiclesById = new Map<Id, Vehicle__c>([
            SELECT Id, Name, Available_Stock__c
            FROM Vehicle__c
            WHERE Id IN :vehicleIds
            FOR UPDATE
        ]);

        Map<Id, Decimal> workingAvailabilityByVehicle = new Map<Id, Decimal>();
        for (Id vehicleId : vehicleIds) {
            Vehicle__c vehicleRecord = vehiclesById.get(vehicleId);
            Decimal availableStock = vehicleRecord == null ? 0 : normalizeStock(vehicleRecord.Available_Stock__c);
            Decimal releasedStock = priorCommittedByVehicle.containsKey(vehicleId)
                ? priorCommittedByVehicle.get(vehicleId)
                : 0;
            workingAvailabilityByVehicle.put(vehicleId, availableStock + releasedStock);
        }

        for (Customer_Order__c orderRecord : orders) {
            if (orderRecord.Vehicle__c == null) {
                orderRecord.addError('Select a vehicle before submitting the order.');
                continue;
            }

            if (orderRecord.Order_Status__c == 'Rejected') {
                continue;
            }

            Vehicle__c vehicleRecord = vehiclesById.get(orderRecord.Vehicle__c);
            if (vehicleRecord == null) {
                orderRecord.addError('The selected vehicle could not be found.');
                continue;
            }

            Decimal requestedQuantity = normalizeQuantity(orderRecord.Quantity__c);
            Decimal workingAvailability = workingAvailabilityByVehicle.get(orderRecord.Vehicle__c);

            if (requestedQuantity <= workingAvailability) {
                orderRecord.Order_Status__c = 'Confirmed';
                workingAvailabilityByVehicle.put(orderRecord.Vehicle__c, workingAvailability - requestedQuantity);
                continue;
            }

            if (orderRecord.Is_Bulk_Order__c) {
                orderRecord.Order_Status__c = 'Pending';
            } else {
                orderRecord.addError(
                    'This vehicle is currently out of stock for the requested quantity and cannot be ordered.'
                );
            }
        }
    }

    public static void syncVehicleStock(List<Customer_Order__c> newOrders, Map<Id, Customer_Order__c> oldMap) {
        Map<Id, Decimal> committedDeltaByVehicle = getCommittedDeltaByVehicle(newOrders, oldMap);
        if (committedDeltaByVehicle.isEmpty()) {
            return;
        }

        Map<Id, Vehicle__c> vehiclesById = new Map<Id, Vehicle__c>([
            SELECT Id, Available_Stock__c
            FROM Vehicle__c
            WHERE Id IN :committedDeltaByVehicle.keySet()
            FOR UPDATE
        ]);

        List<Vehicle__c> updates = new List<Vehicle__c>();
        for (Id vehicleId : committedDeltaByVehicle.keySet()) {
            Vehicle__c vehicleRecord = vehiclesById.get(vehicleId);
            if (vehicleRecord == null) {
                continue;
            }

            Decimal currentAvailableStock = normalizeStock(vehicleRecord.Available_Stock__c);
            Decimal adjustedAvailableStock = currentAvailableStock - committedDeltaByVehicle.get(vehicleId);
            if (adjustedAvailableStock < 0) {
                adjustedAvailableStock = 0;
            }

            updates.add(new Vehicle__c(
                Id = vehicleId,
                Available_Stock__c = adjustedAvailableStock,
                Is_Available__c = adjustedAvailableStock > 0,
                Last_Stock_Checked__c = System.now()
            ));
        }

        if (!updates.isEmpty()) {
            update updates;
        }
    }

    @TestVisible
    private static Map<Id, Decimal> getCommittedDeltaByVehicle(
        List<Customer_Order__c> newOrders,
        Map<Id, Customer_Order__c> oldMap
    ) {
        Map<Id, Decimal> deltasByVehicle = new Map<Id, Decimal>();
        if (newOrders == null || newOrders.isEmpty()) {
            return deltasByVehicle;
        }

        for (Customer_Order__c newOrder : newOrders) {
            Customer_Order__c oldOrder = oldMap == null ? null : oldMap.get(newOrder.Id);

            Decimal previousCommittedQuantity = getCommittedQuantity(oldOrder);
            if (previousCommittedQuantity > 0 && oldOrder.Vehicle__c != null) {
                accumulate(deltasByVehicle, oldOrder.Vehicle__c, -previousCommittedQuantity);
            }

            Decimal newCommittedQuantity = getCommittedQuantity(newOrder);
            if (newCommittedQuantity > 0 && newOrder.Vehicle__c != null) {
                accumulate(deltasByVehicle, newOrder.Vehicle__c, newCommittedQuantity);
            }
        }

        for (Id zeroDeltaVehicleId : getZeroDeltaVehicleIds(deltasByVehicle)) {
            deltasByVehicle.remove(zeroDeltaVehicleId);
        }
        return deltasByVehicle;
    }

    private static Set<Id> getZeroDeltaVehicleIds(Map<Id, Decimal> deltasByVehicle) {
        Set<Id> zeroDeltaVehicleIds = new Set<Id>();
        for (Id vehicleId : deltasByVehicle.keySet()) {
            if (deltasByVehicle.get(vehicleId) == 0) {
                zeroDeltaVehicleIds.add(vehicleId);
            }
        }
        return zeroDeltaVehicleIds;
    }

    private static Decimal getCommittedQuantity(Customer_Order__c orderRecord) {
        if (orderRecord == null || orderRecord.Vehicle__c == null || orderRecord.Order_Status__c != 'Confirmed') {
            return 0;
        }
        return normalizeQuantity(orderRecord.Quantity__c);
    }

    private static Decimal normalizeQuantity(Decimal quantityValue) {
        return quantityValue == null || quantityValue <= 0 ? 1 : quantityValue;
    }

    private static Decimal normalizeStock(Decimal stockValue) {
        return stockValue == null ? 0 : stockValue;
    }

    private static void accumulate(Map<Id, Decimal> valuesByVehicle, Id vehicleId, Decimal value) {
        if (vehicleId == null || value == null) {
            return;
        }
        Decimal currentValue = valuesByVehicle.containsKey(vehicleId) ? valuesByVehicle.get(vehicleId) : 0;
        valuesByVehicle.put(vehicleId, currentValue + value);
    }
}
