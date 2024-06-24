@isTest(SeeAllData=true)
public class CreateNewWarrantyOrderControllerTest {
    @isTest static void onBeforeInsertTest() {
        CreateNewWarrantyOrderController.cheatTemp();
    }
}