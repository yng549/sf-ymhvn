({
    init: function (component, event, helper) {
      helper.dataInit(component, event, helper);
    },
    closeAction : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire()
    },
    
	syncAction : function(component,event,helper) {
        let button = event.getSource();
    	button.set('v.disabled', true);
        var action = component.get('c.recallSyncDMS');
        action.setParams({
            "recordId" : component.get("v.recordId"),
        });
        action.setCallback(this, function(response) {
            
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                button.set('v.disabled', false);
                var apiResponse = response.getReturnValue();
                if(apiResponse.success) {
                    helper.showToast('Success', apiResponse.result);
                    $A.get('e.force:refreshView').fire();
                    $A.get("e.force:closeQuickAction").fire()
                }
				
            }else if (state == "ERROR") {
                button.set('v.disabled', false);
                var errorMsg = action.getError()[0].message;
                helper.showToast('Error',errorMsg);
            }
        });
        $A.enqueueAction(action);
    },
})