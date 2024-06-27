({
  refreshLead: function (component) {
    component.set("v.Spinner", "true");
    var action = component.get("c.updateAvailbleInStock");
    action.setParams({
      strLeadId: component.get("v.recordId")
    });
    action.setCallback(this, function (response) {
      component.set("v.Spinner", "false");
      var state = response.getState();
      if (state === "SUCCESS") {
        var resultsToast = $A.get("e.force:showToast");
        resultsToast.setParams({
          title: "Refreshed",
          type: "success",
          message: "The record was refreshed."
        });
        resultsToast.fire();
        $A.get("e.force:closeQuickAction").fire();
        $A.get("e.force:refreshView").fire();
      } else if (state === "ERROR") {
        var errorToast = $A.get("e.force:showToast");
        resultsToast.setParams({
          title: "Error",
          type: "error",
          message: response.error
        });
        errorToast.fire();
        console.log("Error: " + JSON.stringify(response.error));
      } else {
        console.log(
          "Unknown problem, state: " +
            state +
            ", error: " +
            JSON.stringify(response.error)
        );
      }
    });
    $A.enqueueAction(action);
  }
});