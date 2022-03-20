public with sharing class MaintenanceRequestHelper {
    
    public static String MAINTENANCE = 'Routine Maintenance';
    public static String REPAIR = 'Repair';
    public static String OTHER = 'Other';
    public static String CLOSED = 'Closed';
    
    public static void updateWorkOrders(List<Case> newList, Map<Id, Case> oldMap) {
        // TODO: Complete the method to update workorders
        Map<Id, Case> reqsToProcess = new Map<Id, Case>();
        for(Case req: newList){
            if((req.Type == MAINTENANCE || req.Type == REPAIR) &&
               req.Status == CLOSED && req.Status != oldMap.get(req.id).Status){
               		reqsToProcess.put(req.id, req);
                }
        }
        if(reqsToProcess.isEmpty()){
            return;
        }
        List<Equipment_Maintenance_Item__c> items = [SELECT id, Equipment__c, Equipment__r.Maintenance_Cycle__c, 
                        Equipment__r.Replacement_Part__c,  Quantity__c,   
                        Maintenance_Request__c 
                        FROM Equipment_Maintenance_Item__c
                       WHERE Maintenance_Request__c in: reqsToProcess.keySet()];
        Map<Id, Decimal> oldReqToMaintCycle = new Map<Id, Decimal>();
        for(Equipment_Maintenance_Item__c item: items){
            Decimal cycle = item.Equipment__r.Maintenance_Cycle__c;
            if(!oldReqToMaintCycle.containsKey(item.Maintenance_Request__c) ||
               oldReqToMaintCycle.get(item.Maintenance_Request__c) > cycle){
                oldReqToMaintCycle.put(item.Maintenance_Request__c, cycle);
            }  
                
        }
        
        Map<Id, Case> oldIdToNewMaintReqMap = generateNewMaintReqMap(oldReqToMaintCycle, reqsToProcess);
        List<Equipment_Maintenance_Item__c> newMaintItems = new List<Equipment_Maintenance_Item__c>();
		for(Equipment_Maintenance_Item__c item: items){
            newMaintItems.add(createEqMaintItem(item, oldIdToNewMaintReqMap.get(item.Maintenance_Request__c)));
        }
        insert newMaintItems;
        
        
    }   
    
    private static Map<ID, Case> generateNewMaintReqMap(Map<Id, Decimal> oldReqToMaintCycle, Map<Id, Case> reqsToProcess){
        Map<Id, Case> oldIdToNewMaintReqMap = new Map<Id, Case>();
        for(Id oldCaseId: oldReqToMaintCycle.keySet()){
            oldIdToNewMaintReqMap.put(oldCaseId, createCase(reqsToProcess.get(oldCaseId), oldReqToMaintCycle.get(oldCaseId)));
        }
        insert oldIdToNewMaintReqMap.values();
        
        return oldIdToNewMaintReqMap;
        
    }
    
    private static Case createCase(Case oldCase, Decimal cycle){
        return new Case(
        subject = oldCase.subject,
        Vehicle__c = oldCase.Vehicle__c,
        Type = MAINTENANCE, 
        Date_Reported__c = System.today(),
        Date_Due__c = System.today().addDays(Integer.valueOf(cycle)),
        Status = 'New',
        ParentId = oldCase.Id);
        
    }
    
    private static Equipment_Maintenance_Item__c createEqMaintItem(Equipment_Maintenance_Item__c oldItem, Case newReq){
        return new Equipment_Maintenance_Item__c(
            Maintenance_Request__c = newReq.id,
            Equipment__c = oldItem.Equipment__c,
            Quantity__c = oldItem.Quantity__c
        );
    }
    
}