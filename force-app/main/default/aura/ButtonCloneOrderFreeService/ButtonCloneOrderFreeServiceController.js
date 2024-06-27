({
    doInit : function(component) {
        var action = component.get('c.getInitialData');
        action.setParams({
            recordId : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var apiResponse = response.getReturnValue();
                component.set("v.orderDTO", apiResponse.result);
                console.log(component.get("v.orderDTO").lstOrderItem);
            }else if (state === "ERROR") {
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
    closeQA : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
    refreshView: function(component, event) {
        // refresh the view
        // $A.get('e.force:refreshView').fire();
    }
})