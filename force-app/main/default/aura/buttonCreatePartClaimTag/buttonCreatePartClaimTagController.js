({
	handleSubmit : function(component, event, helper) {
	
	},

	handleClose : function(component, event, helper) {
		$A.get("e.force:closeQuickAction").fire() 
	},

	createPdf : function(component, event, helper) {
		component.set('v.Spinner', 'true');
		var action = component.get('c.createPdfFile');
		action.setParams({
			orderId: component.get('v.recordId')
		});
		action.setCallback(this, function (response) {
			component.set('v.Spinner', 'false');
			var toastEvent = $A.get("e.force:showToast");
			var state = response.getState();
			if (state == 'SUCCESS') {
				$A.get("e.force:closeQuickAction").fire();
				toastEvent.setParams({
					"type": "success",
					"message" : "Dwonload PDF Successfully"
				});
				toastEvent.fire();
				$A.get('e.force:refreshView').fire()
			} else {
				toastEvent.setParams({
					"type": "error",
					"message": response.getError()[0].message
				});
				toastEvent.fire();
			}
		});
		$A.enqueueAction(action);
	}
})