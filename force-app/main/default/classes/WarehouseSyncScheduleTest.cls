@isTest
public class WarehouseSyncScheduleTest {
    // implement scheduled code here
    @isTest
    public static void testShedulable(){
        Test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMock());
        Test.startTest();
        WarehouseSyncSchedule.scheduleMe('test shedule', '0 0 19 * * ?');
        Test.stopTest();
        
        List<AsyncApexJob> jobs = [select id from AsyncApexJob where ApexClass.Name = 'WarehouseCalloutService'];
        System.assertEquals(1, jobs.size());
    }
}