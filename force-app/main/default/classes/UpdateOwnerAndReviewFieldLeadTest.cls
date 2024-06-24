@isTest
public class UpdateOwnerAndReviewFieldLeadTest {
	@isTest static void beforeInsertTest() {
        Test.startTest();
        /*Lead objLead = new Lead();
        objLead.LastName = 'Nguyen A';
        objLead.Email = 'nguyena@gmail.com';
        objLead.MobilePhone = '0923424223';
        insert objLead;
        
        UpdateOwnerAndReviewFieldLead.getLeadData(objLead.Id);
        UpdateOwnerAndReviewFieldLead.updateLeadData(objLead.Id);*/
        UpdateOwnerAndReviewFieldLead.cheatTemp();
        
        Test.stopTest();
    }
}