public class ExternalEquipment {
    public Boolean replacement;
    public Integer quantity;
    public String name;
    public Integer maintenanceperiod;
    public Integer lifespan;
    public Integer cost;
    public String sku;

    public static ExternalEquipment parse(String json) {
        return (ExternalEquipment) System.JSON.deserialize(json, ExternalEquipment.class);
    }
}
