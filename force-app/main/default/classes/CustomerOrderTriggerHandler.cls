public with sharing class CustomerOrderTriggerHandler {
    public static void beforeInsert(List<Customer_Order__c> newOrders) {
        processOrders(newOrders);
    }

    public static void beforeUpdate(List<Customer_Order__c> newOrders, Map<Id, Customer_Order__c> oldMap) {
        processOrders(newOrders);
    }

    @TestVisible
    private static void processOrders(List<Customer_Order__c> orders) {
        if (orders == null || orders.isEmpty()) {
            return;
        }

        applyDefaults(orders);
        DealerAssignmentService.assignNearestDealers(orders);
        validateInventory(orders);
    }

    @TestVisible
    private static void applyDefaults(List<Customer_Order__c> orders) {
        for (Customer_Order__c orderRecord : orders) {
            if (orderRecord.Quantity__c == null || orderRecord.Quantity__c <= 0) {
                orderRecord.Quantity__c = 1;
            }

            if (String.isBlank(orderRecord.Order_Status__c)) {
                orderRecord.Order_Status__c = 'Draft';
            }
        }
    }

    @TestVisible
    private static void validateInventory(List<Customer_Order__c> orders) {
        Set<Id> vehicleIds = new Set<Id>();
        for (Customer_Order__c orderRecord : orders) {
            if (orderRecord.Vehicle__c != null) {
                vehicleIds.add(orderRecord.Vehicle__c);
            }
        }

        Map<Id, Vehicle__c> vehiclesById = vehicleIds.isEmpty()
            ? new Map<Id, Vehicle__c>()
            : new Map<Id, Vehicle__c>([
                SELECT Id, Name, Available_Stock__c
                FROM Vehicle__c
                WHERE Id IN :vehicleIds
            ]);

        for (Customer_Order__c orderRecord : orders) {
            if (orderRecord.Vehicle__c == null) {
                orderRecord.addError('Select a vehicle before submitting the order.');
                continue;
            }

            Vehicle__c vehicleRecord = vehiclesById.get(orderRecord.Vehicle__c);
            if (vehicleRecord == null) {
                orderRecord.addError('The selected vehicle could not be found.');
                continue;
            }

            Decimal requestedQuantity = normalizeQuantity(orderRecord.Quantity__c);
            Decimal availableStock = normalizeStock(vehicleRecord.Available_Stock__c);

            if (availableStock <= 0 || availableStock < requestedQuantity) {
                if (orderRecord.Is_Bulk_Order__c) {
                    orderRecord.Order_Status__c = 'Pending';
                } else {
                    orderRecord.addError(
                        'This vehicle is currently out of stock for the requested quantity and cannot be ordered.'
                    );
                }
                continue;
            }

            orderRecord.Order_Status__c = 'Confirmed';
        }
    }

    private static Decimal normalizeQuantity(Decimal quantityValue) {
        return quantityValue == null || quantityValue <= 0 ? 1 : quantityValue;
    }

    private static Decimal normalizeStock(Decimal stockValue) {
        return stockValue == null ? 0 : stockValue;
    }
}
