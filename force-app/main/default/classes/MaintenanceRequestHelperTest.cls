@isTest
public class MaintenanceRequestHelperTest {
    
    @isTest
    private static void testSuccessOne(){
        
        Product2 equip1 = createEquipment('prod1', 'prc1', 20, 'extprc1');
        Product2 equip2 = createEquipment('prod2', 'prc2', 40, 'extprc2');
        
        Vehicle__c veh = createVehicle('lux car');
        
        insert new List<sObject>{veh, equip1, equip2};
        
        Case maintReq = createCase('case1', veh, MaintenanceRequestHelper.MAINTENANCE, System.today(), System.today(), 'New');
        insert maintReq;
        
        Equipment_Maintenance_Item__c maintItem1 = createEqMaintItem(maintReq, equip1, 1);
        Equipment_Maintenance_Item__c maintItem2 = createEqMaintItem(maintReq, equip2, 1);
        
        insert new List<Equipment_Maintenance_Item__c>{maintItem1, maintItem2};
            
        Test.startTest();
        maintReq.Status = 'Closed';
        update maintReq;
        Test.stopTest();
        
        List<Case> relatedMaintReqs = [select Vehicle__c, Type, Date_Reported__c, Date_Due__c from Case
                                       where Vehicle__c =: veh.id and parentid =: maintReq.Id];
        system.assert(relatedMaintReqs.size() == 1, 'One maint req should be generated');   
        
        System.assertEquals(Date.today().addDays(20), relatedMaintReqs.get(0).Date_Due__c, 'Date should be calculated based on lowest cycle of products'); 
        
        List<Equipment_Maintenance_Item__c> newItems = [SELECT id FROM Equipment_Maintenance_Item__c 
                                                        WHERE Maintenance_Request__c =: relatedMaintReqs.get(0).Id ];
        System.assertEquals(2, newItems.size(), 'Two maint items for the new case should be generated');
        
    }
    
    @isTest
    private static void testNoMaintReq(){
         
        Product2 equip1 = createEquipment('prod1', 'prc1', 20, 'extprc1');
        Product2 equip2 = createEquipment('prod2', 'prc2', 40, 'extprc2');
        
        Vehicle__c veh = createVehicle('lux car');
        
        insert new List<sObject>{veh, equip1, equip2};
        
        Case maintReq = createCase('case1', veh, MaintenanceRequestHelper.OTHER, System.today(), System.today(), 'New');
        insert maintReq;
        
        Equipment_Maintenance_Item__c maintItem1 = createEqMaintItem(maintReq, equip1, 1);
        Equipment_Maintenance_Item__c maintItem2 = createEqMaintItem(maintReq, equip2, 1);
        
        insert new List<Equipment_Maintenance_Item__c>{maintItem1, maintItem2};
            
        Test.startTest();
        maintReq.Status = 'Closed';
        update maintReq;
        Test.stopTest();
        
        List<Case> relatedMaintReqs = [select Vehicle__c, Type, Date_Reported__c, Date_Due__c from Case
                                       where Vehicle__c =: veh.id and parentid =: maintReq.Id];
        system.assert(relatedMaintReqs.size() == 0, 'No maint req should be generated');        
    }
    
    @isTest
    private static void testcreateMaintReqMany(){
        
        integer size = 300;
        List<Product2> equips = new List<Product2>();
        List<Vehicle__c> vehs = new List<Vehicle__c>();
        for(integer i = 0; i < size; i++){
            equips.add(createEquipment('prod' + i, 'prc' + i, 20, 'extprc' + i));
            vehs.add(createVehicle('car ' + i));
        }
        
        insert equips;
        insert vehs;
        
        List<Case> maintReqs = new List<Case>();
        for(integer i = 0; i < size; i++){
            
        	maintReqs.add(createCase('case' + i, vehs.get(i), MaintenanceRequestHelper.REPAIR, System.today(), System.today(), 'New'));
            
        }
        insert maintReqs;
        List<Equipment_Maintenance_Item__c> items = new List<Equipment_Maintenance_Item__c>();
		for(integer i = 0; i < size; i++){        
        	items.add(createEqMaintItem(maintReqs.get(i), equips.get(i), 1));
        }
        insert items;
        
        Test.startTest();
       
        List<Id> reqIds = new List<Id>();
        for(integer i = 0; i < size; i++){  
            Case maintReq = maintReqs.get(i);
        	maintReq.Status = 'Closed';
            reqIds.add(maintReq.id);
        }
        system.debug('maintREq: ' + maintReqs.size());
        update maintReqs;
            
        Test.stopTest();
        
        List<Case> relatedMaintReqs = [select Vehicle__c, Type, Date_Reported__c, Date_Due__c from Case
                                       where parentid IN: reqIds];
        system.assertEquals(size, relatedMaintReqs.size());
        
               
    }
    
    // implement scheduled code here
    private static Case createCase(String subject, Vehicle__c vehicle, String caseType, Date reportedDate, Date dueDate, String status){
        return new Case(
        subject = subject,
        Vehicle__c = vehicle.id,
        Type = caseType, 
        Date_Reported__c = reportedDate,
        Date_Due__c = dueDate,
        Status = status);
        
    }
    
    private static Equipment_Maintenance_Item__c createEqMaintItem(Case req, Product2 equip, Integer quantity){
        return new Equipment_Maintenance_Item__c(
            Maintenance_Request__c = req.id,
            Equipment__c = equip.id,
            Quantity__c = quantity
        );
    }
    
    private static Vehicle__c createVehicle(String name){
        return new Vehicle__c(Name = name);
    }
    
    public static Product2 createEquipment(String name, String prodCode, Integer maintCycle, String extId){
        return new Product2(
            Name = name,
            Maintenance_Cycle__c = maintCycle,
            Warehouse_SKU__c = extId,
            ProductCode = prodCode,
            Replacement_Part__c = true
        );
    }
    
}