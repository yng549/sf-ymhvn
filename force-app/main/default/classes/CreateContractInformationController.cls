public with sharing class CreateContractInformationController {
  /*
   * This function will fetch the RecordTypes of
   * provided object and will return a map of
   * recordTypeId and recordTypeNames
   * it excludes 'master' record type
   * */
  public static Map<Id, String> recordtypemap;
  @AuraEnabled
  public static Map<Id, String> fetchRecordTypeValues(String objectName) {
    List<Schema.RecordTypeInfo> recordtypes = Schema.getGlobalDescribe()
      .get(objectName)
      .getDescribe()
      .getRecordTypeInfos();
    recordtypemap = new Map<Id, String>();
    for (RecordTypeInfo rt : recordtypes) {
      if (rt.getName() != 'Master' && rt.getName().trim() != '')
        recordtypemap.put(rt.getRecordTypeId(), rt.getName());
    }
    return recordtypemap;
  }
  @AuraEnabled
  public static Contract getContractById(String strId) {
    List<Contract> lstContract = [
      SELECT Id, AccountId
      FROM Contract
      WHERE Id = :strId
    ];
    if (!lstContract.isEmpty()) {
      return lstContract[0];
    } else {
      return new Contract();
    }
  }
}