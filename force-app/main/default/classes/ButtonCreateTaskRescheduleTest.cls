@isTest
public class ButtonCreateTaskRescheduleTest {
    @isTest static void onBeforeInsertTest() {
        Test.startTest();
        Lead objLead = new Lead();
        objLead.LastName = 'ava';
        
        insert objLead ;
        
        ButtonCreateTaskReschedule.getInitialData(objLead.Id);
        ButtonCreateTaskReschedule.RescheduleResult objn = new ButtonCreateTaskReschedule.RescheduleResult();
        objn.recordId = objLead.Id;
        objn.dueDate = 2;
        objn.datereschedule = '2022-03-10';
        objn.note = 'Khach chua du tien coc';
        ButtonCreateTaskReschedule.createReschedule(objn);
        Test.stopTest();
    }
}