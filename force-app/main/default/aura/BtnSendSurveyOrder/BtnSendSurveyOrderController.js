({
	noBtn : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire()
    },
    
	yesBtn : function(component, event, helper) {
		component.set('v.showSpinner', true);
        var action = component.get("c.sendSurvey");
        action.setParams({
            orderId : component.get("v.recordId"),
            surveyName : component.get("v.surveyName")
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

                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
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

            }            
        });       
        $A.enqueueAction(action);
    }
})