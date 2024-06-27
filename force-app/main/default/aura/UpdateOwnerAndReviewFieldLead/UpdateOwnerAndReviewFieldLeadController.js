({
    doInit : function(component, event, helper) {
        var strId = component.get('v.recordId');
        helper.handleGetLead(component, strId);
    },
    handleCancelBtn : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },

    handleConvertBtn : function(component, event, helper) {
        var strId = component.get('v.recordId');
        var action = component.get("c.updateLeadData");
        action.setParams({
			strId : strId
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
            var toastEvent = $A.get("e.force:showToast");
			if(state === "SUCCESS") {
                $A.get("e.force:closeQuickAction").fire();
				var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Success!',
                    message: 'The lead has been updated successfully.',
                    duration:' 5000',
                    type: 'success',
                    mode: 'pester'
                });
                toastEvent.fire();
			} else {
                $A.get("e.force:closeQuickAction").fire();
				var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Error!',
                    message: response.getError()[0].message ,
                    duration:' 5000',
                    type: 'Error',
                    mode: 'pester'
                });
                toastEvent.fire();
			}
		});
		$A.enqueueAction(action);
    },

    showToast: function (type, message) {
		var toastEvent = $A.get("e.force:showToast");
		toastEvent.setParams({
			"type": type,
			"message": message
		});
		toastEvent.fire();
	}
})