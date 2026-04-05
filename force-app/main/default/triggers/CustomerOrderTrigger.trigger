trigger CustomerOrderTrigger on Customer_Order__c (before insert, before update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            CustomerOrderTriggerHandler.beforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            CustomerOrderTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}

