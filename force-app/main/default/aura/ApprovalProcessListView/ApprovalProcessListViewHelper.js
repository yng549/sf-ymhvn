({
  COLUMNS: [
    {
      label: "Related To",
      fieldName: "nameUrl",
      type: "url",
      typeAttributes: { label: { fieldName: "TargetObject_Name" }, target: "_blank" }
    },

    { label: "Type", fieldName: "ProcessDefinition_Type" },
    {
      label: "Most Recent Approver",
      fieldName: "Actor_Name"
    },
    {
      label: "Data Submitted",
      fieldName: "CompletedDate",
      type: "DateTime"
    }
  ],

  setColumns: function (cmp) {
    cmp.set("v.columns", this.COLUMNS);
  },

  setData: function (component) {
    var action = component.get("c.getUserApprovalProcess");
    // action.setParams({
    //   strOptyId: component.get("v.recordId")
    // });
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        console.log("Data = " + response.getReturnValue());
        var result = [];
        var rows = response.getReturnValue();
        for (var i = 0; i < rows.length; i++) {
          var row = rows[i];
          row.nameUrl = '/'+rows[i].Id;
          row.TargetObject_Name = rows[i].ProcessInstance.TargetObject.Name;
          row.ProcessDefinition_Type =
            rows[i].ProcessInstance.ProcessDefinition.Type;
          if (rows[i].ActorId != null) {
            row.Actor_Name = rows[i].Actor.Name;
          } else {
            row.Actor_Name = "";
          }
          row.CompletedDate = rows[i].ProcessInstance.CompletedDate;
          result.push(row);
        }
        console.log("result = " + JSON.stringify(result));
        component.set("v.data", result);
      } else if (state === "ERROR") {
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