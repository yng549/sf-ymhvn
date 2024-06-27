({
  handleSubmit: function (component, event, helper) {},

  handleClose: function (component, event, helper) {
    $A.get("e.force:closeQuickAction").fire();
  },

  // handlePrint: function (component, event, helper) {
  //   console.log(window.location.origin);
  //   var vfOrigin = 'https://yamahamotorsvietnam--dev.lightning.force.com';
  //   var vfWindow = component.find('myFrame').getElement().contentWindow;
  //   vfWindow.postMessage('PRINT', vfOrigin);
  // },

  createPdf: function (component, event, helper) {
    component.set("v.Spinner", "true");
    var action = component.get("c.createPdfFile");
    action.setParams({
      orderId: component.get("v.recordId")
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
        $A.get("e.force:closeQuickAction").fire();
        toastEvent.setParams({
          type: "success",
          message: "Download PDF Successfully"
        });
        toastEvent.fire();
        $A.get("e.force:refreshView").fire();
      } else {
        toastEvent.setParams({
          type: "error",
          message: response.getError()[0].message
        });
        toastEvent.fire();
      }
    });
    $A.enqueueAction(action);
  }
});