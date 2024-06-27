({
	handleSyncCMS: function (component, event, helper) {
        var action = component.get("c.syncPromotionToDMS");
        action.setParams({
            recordId : component.get("v.recordId") 
        });
        action.setCallback(this, function(response) {
            $A.get("e.force:closeQuickAction").fire();
           	window.location.reload();
        });
        $A.enqueueAction(action);
    }
})