public with sharing class MaintenanceRequestHelper {
    public static String MAINTENANCE = 'Routine Maintenance';
    public static String REPAIR = 'Repair';
    public static String OTHER = 'Other';
    public static String CLOSED = 'Closed';

    public void updateWorkOrders(List<Case> newRequestsList, Map<Id, Case> oldRequestsMap) {
        List<Id> requestIdsToProcess = getRequestIdsForProcessing(newRequestsList, oldRequestsMap);
        if (requestIdsToProcess.isEmpty()) {
            return;
        }

        List<Case> requestsWithItemsToProcess = getRequestsWithItemsForProcessing(requestIdsToProcess);
        Map<Id, Case> oldIdToNewMaintRequestMap = buildNewRequests(requestsWithItemsToProcess);
        store(oldIdToNewMaintRequestMap.values(), Case.getSObjectType().getDescribe().getLabel());
        List<Equipment_Maintenance_Item__c> items = buildNewRequestItems(
            requestsWithItemsToProcess,
            oldIdToNewMaintRequestMap
        );
        store(items, Equipment_Maintenance_Item__c.getSObjectType().getDescribe().getLabel());
    }

    private List<Id> getRequestIdsForProcessing(List<Case> newRequestsList, Map<Id, Case> oldRequestsMap) {
        List<Id> requestIds = new List<Id>();
        for (Case req : newRequestsList) {
            if (
                (req.Type == MAINTENANCE ||
                req.Type == REPAIR) &&
                req.Status == CLOSED &&
                req.Status != oldRequestsMap.get(req.id).Status
            ) {
                requestIds.add(req.id);
            }
        }
        return requestIds;
    }

    private List<Case> getRequestsWithItemsForProcessing(List<Id> requestIds) {
        return [
            SELECT
                Id,
                Vehicle__c,
                Subject,
                (
                    SELECT
                        id,
                        Equipment__c,
                        Equipment__r.Maintenance_Cycle__c,
                        Equipment__r.Replacement_Part__c,
                        Quantity__c,
                        Maintenance_Request__c
                    FROM Equipment_Maintenance_Items__r
                )
            FROM Case
            WHERE Id IN :requestIds
        ];
    }

    private Map<Id, Case> buildNewRequests(List<Case> oldRequests) {
        Map<Id, Case> oldIdToNewMaintRequestMap = new Map<Id, Case>();

        for (Case oldRequest : oldRequests) {
            Case newRequest = createRequest(oldRequest);
            if (newRequest != null) {
                oldIdToNewMaintRequestMap.put(oldRequest.Id, newRequest);
            }
        }
        return oldIdToNewMaintRequestMap;
    }

    private Case createRequest(Case oldRequest) {
        if (oldRequest.Equipment_Maintenance_Items__r == null || oldRequest.Equipment_Maintenance_Items__r.isEmpty()) {
            return null;
        }
        return new Case(
            subject = oldRequest.subject,
            Vehicle__c = oldRequest.Vehicle__c,
            Type = MAINTENANCE,
            Date_Reported__c = System.today(),
            Date_Due__c = getDueDate(oldRequest.Equipment_Maintenance_Items__r),
            Status = 'New',
            ParentId = oldRequest.Id
        );
    }

    private Date getDueDate(List<Equipment_Maintenance_Item__c> items) {
        Decimal lowestMaintCycle;
        for (Equipment_Maintenance_Item__c item : items) {
            if (lowestMaintCycle == null || item.Equipment__r.Maintenance_Cycle__c < lowestMaintCycle) {
                lowestMaintCycle = item.Equipment__r.Maintenance_Cycle__c;
            }
        }

        return lowestMaintCycle != null ? System.today().addDays(Integer.valueOf(lowestMaintCycle)) : null;
    }

    private List<Equipment_Maintenance_Item__c> buildNewRequestItems(
        List<Case> oldRequests,
        Map<Id, Case> oldIdToNewRequestMap
    ) {
        List<Equipment_Maintenance_Item__c> newMaintItems = new List<Equipment_Maintenance_Item__c>();
        for (Case oldRequest : oldRequests) {
            if (oldIdToNewRequestMap.containsKey(oldRequest.Id)) {
                Id newCaseId = oldIdToNewRequestMap.get(oldRequest.Id).Id;
                for (Equipment_Maintenance_Item__c item : oldRequest.Equipment_Maintenance_Items__r) {
                    newMaintItems.add(createItem(item, newCaseId));
                }
            }
        }
        return newMaintItems;
    }

    private Equipment_Maintenance_Item__c createItem(Equipment_Maintenance_Item__c oldItem, Id newReqId) {
        return new Equipment_Maintenance_Item__c(
            Maintenance_Request__c = newReqId,
            Equipment__c = oldItem.Equipment__c,
            Quantity__c = oldItem.Quantity__c
        );
    }

    private void store(List<sObject> records, String objectName) {
        Database.SaveResult[] saveResultList = Database.insert(records, false);
        errorHandling(saveResultList, objectName);
    }

    private void errorHandling(Database.SaveResult[] saveResultList, String objectName) {
        for (Database.SaveResult saveRes : saveResultList) {
            if (!saveRes.isSuccess()) {
                for (Database.Error error : saveRes.getErrors()) {
                    System.debug('Error in saving records for ' + objectName + ' : ');
                    System.debug(error.getStatusCode() + ': ' + error.getMessage());
                    System.debug(objectName + ' fields caused the error: ' + error.getFields());
                }
            }
        }
    }
}
