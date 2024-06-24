@isTest
public class TriggerContractInformationHandlerTest {
  @isTest
  static void onAfterInsertTest() {
    Contract_Information__c objCI = new Contract_Information__c();
    objCI.RecordTypeId = Schema.SObjectType.Contract_Information__c.getRecordTypeInfosByDeveloperName()
      .get('Person')
      .getRecordTypeId();
    objCI.Name = 'Test';
    insert objCI;
  }

  //   private static Contract createContract(){
  //     Contract c = new Contract();
  //     c.
  //   }
}