@isTest
public class RefreshLeadControllerTest {
    @isTest static void onBeforeInsertTest() {
        Lead objLead = new Lead();
        objLead.LastName = 'ava';
        
        insert objLead ;
        //RefreshLeadController vn = new RefreshLeadController();
        RefreshLeadController.updateAvailbleInStock(objLead.Id);
        //RefreshLeadController.checkAvailableInStock(objLead.Id);
    }
}