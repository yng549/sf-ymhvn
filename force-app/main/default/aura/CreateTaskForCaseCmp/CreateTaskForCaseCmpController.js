({
    closeQA : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
    init : function(component, evt) {
        $A.get('e.force:refreshView').fire();
        var action = component.get("c.getCases");
        action.setParams({
            "strCaseId": component.get("v.recordId")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.cases", response.getReturnValue());
                component.set('v.flag', true);
                
            }
        });
        $A.enqueueAction(action);
    },
    waiting: function(component, event, helper) {
        component.set("v.HideSpinner", true);
       },
       doneWaiting: function(component, event, helper) {
        component.set("v.HideSpinner", false);
       }
})