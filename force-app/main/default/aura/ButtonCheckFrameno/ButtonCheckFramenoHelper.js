({
	dataInit : function(component, event, helper) {
        var action = component.get("c.getInitialData");
        action.setParams({
            "recordId" : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set("v.assetRecord", result.result);
            }
            else if (state === "ERROR") {
                this.showToast('error', response.getError()[0].message);
                component.set("v.isValidate", true);
            }
        });
        $A.enqueueAction(action);
    },
    serverSideCall : function(component,action) {
        return new Promise(function(resolve, reject) { 
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    resolve(response.getReturnValue());
                } else {
                    reject(new Error(response.getError()[0].message));
                }
            }); 
            $A.enqueueAction(action);
        });
    },
    showToast : function(type, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            type: type,
            "message": message
        });
        toastEvent.fire();
    },
})