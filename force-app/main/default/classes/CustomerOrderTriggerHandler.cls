public with sharing class CustomerOrderTriggerHandler {
    public static void beforeInsert(List<Customer_Order__c> newOrders) {
        processOrders(newOrders, null);
    }

    public static void beforeUpdate(List<Customer_Order__c> newOrders, Map<Id, Customer_Order__c> oldMap) {
        processOrders(newOrders, oldMap);
    }

    @TestVisible
    private static void processOrders(List<Customer_Order__c> orders, Map<Id, Customer_Order__c> oldMap) {
        if (orders == null || orders.isEmpty()) {
            return;
        }

        applyDefaults(orders);
        DealerAssignmentService.assignNearestDealers(orders);
        CustomerOrderInventoryService.allocateInventory(orders, oldMap);
    }

    public static void afterInsert(List<Customer_Order__c> newOrders) {
        CustomerOrderInventoryService.syncVehicleStock(newOrders, null);
        EmailNotificationService.sendOrderStatusNotifications(newOrders, null);
    }

    public static void afterUpdate(List<Customer_Order__c> newOrders, Map<Id, Customer_Order__c> oldMap) {
        CustomerOrderInventoryService.syncVehicleStock(newOrders, oldMap);
        EmailNotificationService.sendOrderStatusNotifications(newOrders, oldMap);
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
}
