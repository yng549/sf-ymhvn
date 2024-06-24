@isTest
public class CheckLeadBeforeConvertOrUnqualifieTest {
    @isTest
    static void test_getInitialData(){
        Test.startTest();
      
        Lead l = new Lead();
        l.LastName = 'LastName';
        //l.Customer_Account__c = acc2.Id;
        //l.Product__c = p.Id;
        l.Phone = '0938707111';
        l.Email = 'abc@abc.cac';
        l.MobilePhone = '0938707111';
        l.OwnerId = [select id from user where Profile.Name = 'Community Sale Profile' and isactive = true limit 1].Id;
        //l.IsConverted = true;
        //l.ConvertedOpportunityId = opty.Id;
        //l.ConvertedAccountId = acc1.Id;
        //l.ConvertedDate = system.today();
        insert l; 
        
        Set<Id> SetLeadID = new Set<ID>();
        List<Lead> lstLead = new List<Lead>();
        lstLead.add(l);
        SetLeadID.add(l.ID);
        Map<Id, Lead> MapLead = new Map<Id, Lead>();
        MapLead.put(l.ID, l);
        
        //CheckLeadBeforeConvertOrUnqualifie cbs = new CheckLeadBeforeConvertOrUnqualifie();
        
        CheckLeadBeforeConvertOrUnqualifie.cheatTemp();
        //User objUser = CheckLeadBeforeConvertOrUnqualifie.gerUserMarketting();
        //CheckLeadBeforeConvertOrUnqualifie.updateTaskComplete(lstLead);
        //List<Lead> lstLJK = CheckLeadBeforeConvertOrUnqualifie.getLstLead(SetLeadID);
        //List<Task> lstTask = CheckLeadBeforeConvertOrUnqualifie.getLstTask(SetLeadID);
        
        Test.stopTest();
    }
}