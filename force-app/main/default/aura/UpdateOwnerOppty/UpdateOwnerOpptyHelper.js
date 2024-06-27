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
				var objOppty = response.getReturnValue();
                component.set("v.objOppty", objOppty);
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
	},

	fetchPicklist : function(component){
        var action = component.get("c.getUser");
		action.setParams({
			strProfileName : 'Community Sale Sup'
		});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                var users = [];
                var result = response.getReturnValue();
                for(var obj in result){
					console.log(obj);
                    users.push({value:result[obj].Name, key:obj});
                }
                component.set("v.mapUserSale", users);
            } 
        });
        $A.enqueueAction(action);
    }
})