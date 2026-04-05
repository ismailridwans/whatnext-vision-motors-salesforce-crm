trigger CustomerOrderTrigger on Customer_Order__c (before insert, before update, after insert, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            CustomerOrderTriggerHandler.beforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            CustomerOrderTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
    } else if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            CustomerOrderTriggerHandler.afterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            CustomerOrderTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
