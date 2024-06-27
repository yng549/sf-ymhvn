({
  /*
   * This method is being called from init event
   * to fetch all available recordTypes
   * */

  fetchListOfRecordTypes: function (component, event, helper) {
    var action = component.get("c.fetchRecordTypeValues");
    //pass the object name here for which you want
    //to fetch record types
    action.setParams({
      objectName: "Order"
    });
    action.setCallback(this, function (response) {
      var mapOfRecordTypes = response.getReturnValue();
      component.set("v.mapOfRecordType", mapOfRecordTypes);
      var recordTypeList = [];
      //Creating recordTypeList from retrieved Map
      for (var key in mapOfRecordTypes) {
        if (key === "012O0000000UmmeIAC" || key === "012O0000000UmmAIAS") {
          recordTypeList.push(mapOfRecordTypes[key]);
        }
      }
      if (recordTypeList.length == 0) {
        helper.closeModal();
        //Calling CreateRecord modal here without providing recordTypeId
        helper.showCreateRecordModal(component, "", "Order");
      } else {
        component.set("v.lstOfRecordType", recordTypeList);
      }
    });

    $A.enqueueAction(action);
  },

  /*
 * This method will be called when "Next" button is clicked
 * It finds the recordTypeId from selected recordTypeName
 * and passes same value to helper to create a record
 * */

  createRecord: function (component, event, helper, sObjectRecord) {
    var action2 = component.get("c.getUserById");
    var userId = $A.get("$SObjectType.CurrentUser.Id");
    action2.setParams({
      strId: userId
    });
    action2.setCallback(this, function (response) {
      var objUser = response.getReturnValue();
      component.set("v.objUser", objUser);
    });
    var action = component.get("c.getAssetById");
    action.setParams({
      strId: component.get("v.recordId")
    });
    
    action.setCallback(this, function (response) {
      var selectedRecordTypeName = "012O0000000UmmAIAS";
      var objAsset = response.getReturnValue();
      component.set("v.objAsset", objAsset);
      if (selectedRecordTypeName != "") {
        var selectedRecordTypeId = "012O0000000UmmAIAS";
       
        helper.closeModal();
        helper.showCreateRecordModal(component, selectedRecordTypeId, "Order");
      } else {
        alert("You did not select any record type");
      }
    });
    $A.enqueueAction(action2);
    $A.enqueueAction(action);
  },

  /*
   * closing quickAction modal window
   * */
  closeModal: function (component, event, helper) {
    helper.closeModal();
  }
});