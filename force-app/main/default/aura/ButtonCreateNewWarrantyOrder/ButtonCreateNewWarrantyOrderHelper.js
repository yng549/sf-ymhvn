({
  /*

     * This methid takes recordTypeId and entityTypeName parameters
     * and invoke standard force:createRecord event to create record
     * if recordTypeIs is blank, this will create record under master recordType
     * */
  showCreateRecordModal: function (component, recordTypeId, entityApiName) {
    debugger;
    var createRecordEvent = $A.get("e.force:createRecord");
    if (createRecordEvent) {
      //checking if the event is supported
      if (recordTypeId) {
        var objectAsset = component.get("v.objAsset");
        var objectUser = component.get("v.objUser");
        var today = new Date();
      
        // var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        //if recordTypeId is supplied, then set recordTypeId parameter
        createRecordEvent.setParams({
          entityApiName: entityApiName,
          recordTypeId: recordTypeId,
          defaultFieldValues: {
            Asset__c: component.get("v.recordId"),
            AccountId: objectAsset.Account_Customer__c,
            DO_DL__c: objectUser.AccountId,
            Status: "New",
            EffectiveDate: today.toISOString(),
            Bike_Receiving_Date__c: today.toISOString(),
            Service_Job_Start_Date__c: today.toISOString(),
            // Bike_Delivery_Date__c: today.toISOString(),
            // Service_Job_End_Date__c : today.toISOString(),
            Cashier__c : objectUser.ContactId
          }
        });
      }
      createRecordEvent.fire();
    } else {
      alert("This event is not supported");
    }
  },

  /*
   * closing quickAction modal window
   * */
  closeModal: function () {
    var closeEvent = $A.get("e.force:closeQuickAction");

    if (closeEvent) {
      closeEvent.fire();
    } else {
      alert(
        "force:closeQuickAction event is not supported in this Ligthning Context"
      );
    }
  }
});