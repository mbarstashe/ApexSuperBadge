public without sharing class WarehouseCalloutService implements Queueable, Database.AllowsCallouts {
    private static final String WAREHOUSE_URL = 'https://th-superbadge-apex.herokuapp.com/equipment';

    public void execute(QueueableContext context) {
        List<ExternalEquipment> externalEquipmentList = getEquipmentFromWarehouse();
        if (externalEquipmentList == null) {
            return;
        }

        List<Product2> products = convertFrom(externalEquipmentList);

        Database.upsert(products, Product2.Fields.Warehouse_SKU__c, false);
    }

    private static List<Product2> convertFrom(List<ExternalEquipment> externalEquipmentList) {
        List<Product2> products = new List<Product2>();
        for (ExternalEquipment extEquip : externalEquipmentList) {
            products.add(convertFrom(extEquip));
        }
        return products;
    }

    public static List<ExternalEquipment> getEquipmentFromWarehouse() {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(WAREHOUSE_URL);
        request.setMethod('GET');
        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200) {
            return (List<ExternalEquipment>) JSON.deserialize(response.getBody(), List<ExternalEquipment>.class);
        } else {
            return null;
        }
    }

    public static Product2 convertFrom(ExternalEquipment extEquip) {
        return new Product2(
            name = extEquip.name,
            Cost__c = extEquip.cost,
            Replacement_Part__c = true,
            //TODO: Ask BA how to map
            //Current_Inventory__c =
            Warehouse_SKU__c = extEquip.sku,
            Maintenance_Cycle__c = extEquip.maintenanceperiod,
            Lifespan_Months__c = extEquip.lifespan
        );
    }
}
