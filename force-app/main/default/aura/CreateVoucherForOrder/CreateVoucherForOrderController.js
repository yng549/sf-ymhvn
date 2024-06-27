({
    closeQA : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
    init : function(component, evt) {
        $A.get('e.force:refreshView').fire();
        var action = component.get("c.getPromotionByRecordTypeVoucher");
        action.setParams({
            "strOrderID": component.get("v.recordId")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.objPromotion", response.getReturnValue().result);
                var actionCreatedVoucher = component.get("c.getObjOrder");
                actionCreatedVoucher.setParams({
                    "strOrderID": component.get("v.recordId")
                });
                actionCreatedVoucher.setCallback(this, function(response1){
                    var state1 = response1.getState();
                    if (state1 === "SUCCESS") {
                        component.set("v.objOrder", response1.getReturnValue());
                    } else if (state1 === "ERROR") {
                        let error1s = response1.getError();
                        var toastEvent1 = $A.get("e.force:showToast");
                        toastEvent1.setParams({
                            "type": "error",
                            "title": "Error! ",
                            "message": error1s[0].message
                        });
                        toastEvent1.fire();
                    }
                });
                $A.enqueueAction(actionCreatedVoucher);
            } else if (state === "ERROR") {
                let errors = response.getError();
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": "Error! ",
                    "message": errors[0].message
                });
                toastEvent.fire();
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