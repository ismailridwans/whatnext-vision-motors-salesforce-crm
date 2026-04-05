global with sharing class VehicleInventoryScheduler implements Schedulable {
    global void execute(SchedulableContext scheduledContext) {
        Database.executeBatch(new VehicleInventoryBatch(), 50);
    }
}

