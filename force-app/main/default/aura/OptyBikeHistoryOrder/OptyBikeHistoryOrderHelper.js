({
  COLUMNS: [
     {
      label: "Order Number",
      fieldName: "nameUrl",
      type: "url",
      typeAttributes: { label: { fieldName: "OrderNumber" }, target: "_blank" }
    },
    {
      label: "Account",
      fieldName: "Account_Name"
    },
    {
      label: "Status",
      fieldName: "Status"
    },
    {
      label: "Order Record Type",
      fieldName: "RecordType_Name"
    },
    {
      label: "Owner",
      fieldName: "Owner_Name"
    }
  ],

  setColumns: function (cmp) {
    cmp.set("v.columns", this.COLUMNS);
  },

  flattenObject: function (propName, obj) {
    var flatObject = [];

    for (var prop in obj) {
      //if this property is an object, we need to flatten again
      var propIsNumber = isNaN(propName);
      var preAppend = propIsNumber ? propName + "_" : "";
      if (typeof obj[prop] == "object") {
        flatObject[preAppend + prop] = Object.assign(
          flatObject,
          this.flattenObject(preAppend + prop, obj[prop])
        );
      } else {
        flatObject[preAppend + prop] = obj[prop];
      }
    }
    return flatObject;
  },

  flattenQueryResult: function (listOfObjects) {
    if (typeof listOfObjects != "Array") {
      var listOfObjects = [listOfObjects];
    }

    // console.log("List of Objects is now....");
    // console.log(listOfObjects);
    for (var i = 0; i < listOfObjects.length; i++) {
      var obj = listOfObjects[i];
      for (var prop in obj) {
        if (!obj.hasOwnProperty(prop)) continue;
        if (typeof obj[prop] == "object" && typeof obj[prop] != "Array") {
          obj = Object.assign(obj, this.flattenObject(prop, obj[prop]));
        } else if (typeof obj[prop] == "Array") {
          for (var j = 0; j < obj[prop].length; j++) {
            obj[prop + "_" + j] = Object.assign(
              obj,
              this.flattenObject(prop, obj[prop])
            );
          }
        }
      }
    }
    return listOfObjects;
  },

  setData: function (component) {
    var action = component.get("c.getOrderHistoryOpty");
    action.setParams({
      strOptyId: component.get("v.recordId")
    });
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        var result = [];
        var rows = response.getReturnValue();
        for (var i = 0; i < rows.length; i++) {
          var row = rows[i];
          row.nameUrl = '/'+rows[i].Id;
          result.push(row);
        }
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