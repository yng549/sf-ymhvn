({
  getContractById: function (component) {
    var action = component.get("c.getContractById");
    action.setParams({
      strId: component.get("v.recordId")
    });

    action.setCallback(this, function (response) {
      var objContract = response.getReturnValue();
      component.set("v.objContract", objContract);
    });
    $A.enqueueAction(action);
  },
  /*
   * This methid takes recordTypeId and entityTypeName parameters
   * and invoke standard force:createRecord event to create record
   * if recordTypeIs is blank, this will create record under master recordType
   * */
  showCreateRecordModal: function (component, recordTypeId, entityApiName) {
    // debugger;
    var LOOKUP = "LOOKUP";
    var createRecordEvent = $A.get("e.force:createRecord");
    if (createRecordEvent) {
      //checking if the event is supported
      if (recordTypeId) {
        var objectContract = component.get("v.objContract");
        //if recordTypeId is supplied, then set recordTypeId parameter
        createRecordEvent.setParams({
          entityApiName: entityApiName,
          recordTypeId: recordTypeId,
          navigationLocation: LOOKUP,
          defaultFieldValues: {
            Account__c: objectContract.AccountId,
            Contract__c: component.get("v.recordId")
          },
          panelOnDestroyCallback: function (event) {
            $A.get("e.force:refreshView").fire();
            // var navigateEvent = $A.get("e.force:navigateToSObject");
            // navigateEvent.setParams({ recordId: component.get("v.recordId") });
            // navigateEvent.fire();
          }
        });
      } else {
        //else create record under master recordType
        createRecordEvent.setParams({
          entityApiName: entityApiName,
          defaultFieldValues: {}
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