@isTest
public class ConvertLeadControllerTest {
	@isTest static void beforeInsertTest() {
        Test.startTest();
        Lead objLead = new Lead();
        objLead.LastName = 'Nguyen A';
        objLead.Email = 'nguyena@gmail.com';
        objLead.MobilePhone = '0923424223';
        insert objLead;
        
        ConvertLeadController.getInitialData(objLead.Id);
        
        ConvertLeadController.saveEdited('ab@gmail.com','09234239829',objLead.Id);
    	ConvertLeadController.convertLead(objLead.Id);
        
        Test.stopTest();
    }
}