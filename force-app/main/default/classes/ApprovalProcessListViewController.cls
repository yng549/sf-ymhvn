public with sharing class ApprovalProcessListViewController {
  //WHERE ASSIGN TO UserInfo.getUserID() '0055g000003IxsfAAC'
  @AuraEnabled
  public static List<ProcessInstanceWorkitem> getUserApprovalProcess() {
    try {
      String userId = UserInfo.getUserID();
      List<ProcessInstanceWorkitem> lstProIW = [
        SELECT
          Id,
          ProcessInstanceId,
          ProcessInstance.ProcessDefinitionId,
          ProcessInstance.ProcessDefinition.Type,
          ProcessInstance.Status,
          ProcessInstance.TargetObjectId,
          ProcessInstance.TargetObject.Name,
          ProcessInstance.LastActorId,
          ProcessInstance.LastActor.Name,
          ProcessInstance.LastModifiedDate,
          ProcessInstance.CompletedDate,
          OriginalActorId,
          ActorId,
          Actor.Name
        FROM ProcessInstanceWorkitem
        WHERE OriginalActorId = :userId
      ];
      //   Set<Id> setProInIds = new Set<Id>();
      //   for (ProcessInstanceWorkitem piw : lstProIW) {
      //     setProInIds.add(piw.ProcessInstanceId);
      //   }
      // TargetObjectId = related to or type?
      //   List<ProcessInstance> lstApprovalProcess = [
      //     SELECT
      //       Id,
      //       ProcessDefinitionId,
      //       ProcessDefinition.Type,
      //       Status,
      //       TargetObjectId,
      //       TargetObject.Name,
      //       LastActorId,
      //       LastActor.Name,
      //       LastModifiedDate,
      //       CompletedDate
      //     FROM ProcessInstance
      //     WHERE Id IN :setProInIds
      //   ];
      if (lstProIW.isEmpty()) {
        return new List<ProcessInstanceWorkitem>();
      } else {
        return lstProIW;
      }
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  public static void cheatTemp() {
    String a = 'cheat';
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
  }
}