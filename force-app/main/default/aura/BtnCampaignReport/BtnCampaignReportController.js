({
	noBtn : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire()
    },
    
	yesBtn : function(component, event, helper) {
		component.set('v.showSpinner', true);
        var action = component.get("c.calculateCamp");
        action.setParams({
            recordId : component.get("v.recordId")
        });
        action.setCallback(this,function(response){
            var response = response.getReturnValue();
            if(response.success)
            {
                component.set('v.showSpinner', false);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": response.result,
                    "type":"success"
                });
                toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire()
            }
            else
            {
                component.set('v.showSpinner', false);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "message": response.error
                });
                toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire()
            }
            
        });       
        $A.enqueueAction(action);
    }
})