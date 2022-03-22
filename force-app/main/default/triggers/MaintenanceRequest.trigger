trigger MaintenanceRequest on Case(before update, after update) {
    if (Trigger.isUpdate && Trigger.isAfter) {
        MaintenanceRequestHelper helper = new MaintenanceRequestHelper();
        helper.updateWorkOrders(Trigger.new, Trigger.oldMap);
    }
}