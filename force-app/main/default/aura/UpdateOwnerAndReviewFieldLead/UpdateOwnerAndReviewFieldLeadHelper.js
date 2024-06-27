({
    handleGetLead: function(component, strId) {
		var action = component.get("c.getLeadData");
		action.setParams({
			strId: strId
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			console.log(state);
			if(state === "SUCCESS") {
				var objectLead = response.getReturnValue();
                component.set("v.objLead", objectLead);
			} else {
				this.showToast('error', response.getError()[0].message);
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