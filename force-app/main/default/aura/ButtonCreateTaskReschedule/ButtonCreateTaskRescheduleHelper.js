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
                component.set("v.reschedule", result.result);
            }
            else if (state === "ERROR") {
                this.showToast('error', response.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    createTaskHelper : function(component, event, helper) {
        var req = component.get("v.reschedule");
        var action = component.get("c.createReschedule");
        action.setParams({
            "req" : req
        });
        action.setCallback(this,function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title":"Success",
                    "type":"success",
                    "message":"Form submitted successfully.", 
                });
                toastEvent.fire();
                $A.get('e.force:refreshView').fire();
                $A.get("e.force:closeQuickAction").fire();
            } else if(state === "ERROR"){
                    var errors = action.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "title":"Error",
                                "type":"error",
                                "message": errors[0].message,                        
                            });
                            toastEvent.fire();
                        }
                    }
                }
            });
        $A.enqueueAction(action);
    },
})