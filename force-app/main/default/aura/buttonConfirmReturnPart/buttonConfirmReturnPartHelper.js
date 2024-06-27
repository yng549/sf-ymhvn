({
    getProfileNameUser: function(component, event) {
        var action = component.get("c.fetchUser");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
                component.set("v.userInfo", storeResponse);
            }
        });
        $A.enqueueAction(action);
    },

    saveCase : function(component, event) {
        component.set("v.flag", false);
        var objCase = component.get("v.objCase");
        var action = component.get("c.updateCase");
        action.setParams({
            objCase : objCase
        });
        action.setCallback(this,function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                this.showMyToast('success', 'The record update successfully');
                $A.get("e.force:closeQuickAction").fire();
                $A.get('e.force:refreshView').fire();
            } else if(state === "ERROR"){
                var errors = action.getError();
                if (errors) {
                    component.set("v.flag", true);
                    if (errors[0] && errors[0].message) {
                        this.showMyToast('success', errors[0].message);
                    }
                }
            }
            component.set("v.flag", true);
        });       
        $A.enqueueAction(action);
    },

    getObjectCase: function(component, event) {
        var action = component.get("c.getAssetByCaseId");
        // pass the apex method parameters to action
        action.setParams({
            strCaseId: component.get("v.recordId")
        });
        action.setCallback(this, function(actionResult) {
        var state = actionResult.getState();
        if (state === "SUCCESS") {
            //set response value in ListOfContact attribute on component.
            component.set("v.objCase", actionResult.getReturnValue());
            // set deafult count and select all checkbox value to false on load
        }
        });
        $A.enqueueAction(action);
    },

    getPicklistValues: function(component, event) {
        var action = component.get("c.getIndustryFieldValue");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                var fieldMap = [];
                for(var key in result){
                    fieldMap.push({key: key, value: result[key]});
                }
                component.set("v.fieldMap", fieldMap);
            }
        });
        $A.enqueueAction(action);
    },

    showMyToast : function(type, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": type,
            "title": type + "!",
            "message": message
        });
        toastEvent.fire();
    }
})