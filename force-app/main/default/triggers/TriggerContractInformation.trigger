trigger TriggerContractInformation on Contract_Information__c(
  before insert,
  after insert
) {
  if (Trigger.isAfter && Trigger.isInsert) {
    TriggerContractInformationHandler.onAfterInsert(Trigger.new);
  }
}