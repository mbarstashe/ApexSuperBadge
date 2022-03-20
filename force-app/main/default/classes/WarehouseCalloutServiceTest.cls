@IsTest
private class WarehouseCalloutServiceTest {
   
    @testSetup static void setup(){
        
        Product2 equip1 = MaintenanceRequestHelperTest.createEquipment('test', '', 10, '100003');
        insert equip1;
    }
    
    
    @isTest
    private static void testCalloutServiceSuccess(){
        Test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMock());
        
        Test.startTest();
        System.enqueueJob(new WarehouseCalloutService());
        Test.stopTest();
        
        List<Product2> equipList = [select id, name, Cost__c, Maintenance_Cycle__c, Current_Inventory__c, Warehouse_SKU__c, Replacement_Part__c 
                                    from Product2 where Warehouse_SKU__c in ('100003', '100004')];
        
        system.assertEquals(2, equipList.size());
        for(Product2 equip: equipList){
            if(equip.Warehouse_SKU__c == '100003'){
                System.assertEquals('Generator 1000 kW', equip.Name);
                System.assertEquals(5000, equip.Cost__c);
            }
            if(equip.Warehouse_SKU__c == '100004'){
                System.assertEquals('Cooling Fan', equip.Name);
                System.assertEquals(300, equip.Cost__c);
            }
            System.assertEquals(true, equip.Replacement_Part__c);
        }
        
    }
    
     @isTest
    private static void testCalloutServiceFail(){
        Test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMockFailure());
        
        Test.startTest();
        System.enqueueJob(new WarehouseCalloutService());
        Test.stopTest();
        
        List<Product2> equipList = [select id, name, Cost__c, Maintenance_Cycle__c, Current_Inventory__c, Warehouse_SKU__c, Replacement_Part__c 
                                    from Product2 where Warehouse_SKU__c in ('100003', '100004')];
        
        system.assertEquals(1, equipList.size());
        for(Product2 equip: equipList){
            if(equip.Warehouse_SKU__c == '100003'){
                System.assertEquals('test', equip.Name);
                
            }
           
        }
        
    }


}