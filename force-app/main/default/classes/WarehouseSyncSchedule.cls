global without sharing class WarehouseSyncSchedule implements Schedulable {
    global void execute(SchedulableContext SC) {
        System.enqueueJob(new WarehouseCalloutService());
    }

    public static void scheduleMe(String name, String params) {
        WarehouseSyncSchedule sheduler = new WarehouseSyncSchedule();
        system.schedule(name, params, sheduler);
    }
}
