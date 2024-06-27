({
  handleSubmit: function (component, event, helper) { },

  handleClose: function (component, event, helper) {
    $A.get("e.force:closeQuickAction").fire();
  },

  newComponent: function (component) {
    var newEvent = $A.get("e.force:navigateToComponent");
    var recordIdPass = component.get("v.recordId")
    newEvent.setParams({
      componentDef: "c:buttonSendEmail",
      componentAttributes: {
        recordOppty: recordIdPass
      }
    });
    newEvent.fire();
  },

  showPopup: function (component, event, helper) {
    // var cmpTarget = component.find('Modalbox');
    // var cmpBack = component.find('Modalbackdrop');
    // $A.util.addClass(cmpTarget, 'slds-fade-in-open');
    // $A.util.addClass(cmpBack, 'slds-backdrop--open'); 
    component.set("v.displayModal", true);
  },

  createPdf: function (component, event, helper) {
    component.set("v.Spinner", "true");
    var action = component.get("c.createPdfFile");
    var action2 = component.get("c.updateOpty");
    action.setParams({
      opportunityId: component.get("v.recordId")
    });
    action2.setParams({
      opportunityId: component.get("v.recordId")
    });

    action.setCallback(this, function (response) {
      component.set("v.Spinner", "false");
      var toastEvent = $A.get("e.force:showToast");
      var state = response.getState();
      if (state == "SUCCESS") {
        var files = response.getReturnValue();
        for (var key in files) {
          var strFile = "data:application/pdf;base64," + files[key];
          download(strFile, key, "application/pdf");
        }
        action2.setCallback(this, function (response2) {
          var state2 = response2.getState();
          if (state2 == "SUCCESS") {
              toastEvent.setParams({
                type: "success",
                message: "Download PDF Successfully"
              });
              toastEvent.fire();
              $A.get("e.force:refreshView").fire();
              $A.get("e.force:closeQuickAction").fire();

          } else {
            toastEvent.setParams({
              type: "error",
              message: response.getError()[0].message
            });
            toastEvent.fire();
          }
        });


      } else {
        toastEvent.setParams({
          type: "error",
          message: response.getError()[0].message
        });
        toastEvent.fire();
      }
    });
    $A.enqueueAction(action);
    $A.enqueueAction(action2);
  },

  closeBtn: function (component, event, helper) {
    component.set("v.displayModal", false);
  }


});