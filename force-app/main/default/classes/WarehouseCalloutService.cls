public with sharing class WarehouseCalloutService implements Queueable, Database.AllowsCallouts {
    private static final String WAREHOUSE_URL = 'https://th-superbadge-apex.herokuapp.com/equipment';
    public void execute(QueueableContext context) {
        // awesome code here
        List<ExternalEquipment> externalEquipmentList = readDataCallout();
        if(externalEquipmentList == null){
            return;
        }
        
        List<Product2> products = new List<Product2>();
        for(ExternalEquipment extEquip : externalEquipmentList){
            products.add(convertExternalEquipToProduct(extEquip));
        }
        
        Schema.SObjectField uniqueId = Product2.Fields.Warehouse_SKU__c;
        Database.upsert(products, uniqueId, false);
        
        
    }
    
    public static List<ExternalEquipment> readDataCallout(){
        
        Http http = new Http();
		HttpRequest request = new HttpRequest();
		request.setEndpoint(WAREHOUSE_URL);
		request.setMethod('GET');
		HttpResponse response = http.send(request);
		// If the request is successful, parse the JSON response.
		if(response.getStatusCode() == 200) {
            
    		
    		return (List<ExternalEquipment>) JSON.deserialize(response.getBody(), List<ExternalEquipment>.class);
        }else{
            return null;
        }

    }
    
    public static Product2 convertExternalEquipToProduct(ExternalEquipment extEquip){
        return new Product2(
            name = extEquip.name,
            Cost__c = extEquip.cost, 
            Replacement_Part__c = true, 
            //Current_Inventory__c = extEquip.x_id, 
            Warehouse_SKU__c = extEquip.sku, 
            Maintenance_Cycle__c = extEquip.maintenanceperiod,
            Lifespan_Months__c = extEquip.lifespan
        );
    }
}