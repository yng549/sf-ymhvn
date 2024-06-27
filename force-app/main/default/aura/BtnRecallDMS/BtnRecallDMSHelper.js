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
                component.set("v.isValid", result.result);
            }
            else if (state === "ERROR") {
                this.showToast('error', response.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    showToast : function(type, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "message": message,
            type: type
        });
        toastEvent.fire();
    },
})