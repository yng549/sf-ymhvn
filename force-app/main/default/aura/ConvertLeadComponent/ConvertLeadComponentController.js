({
  	init: function (component, event, helper) {
      helper.dataInit(component, event, helper);
    },
    editTalent : function( component, event, helper ) {
        var leadRecord = component.get("v.leadrecord");
        leadRecord.editMode = true;
        component.set( "v.leadrecord", leadRecord);
    },
    saveEditedTalent:function(component, event, helper){
        var allValid = component.find('field').reduce(function (validSoFar, inputCmp) {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        if (allValid) {
            var action = component.get("c.saveEdited");
            var leadrecord = component.get('v.leadrecord');
            var recordId = component.get('v.recordId');        
            action.setParams({
                "email": leadrecord.lead.Email, 
                "phone": leadrecord.lead.MobilePhone,
                "recordId": recordId});
            action.setCallback(this, function(response){
                var state = response.getState();
                if(state == "SUCCESS") {
                    var eventToast = $A.get("e.force:showToast");
                    eventToast.setParams({
                        "title":'Success',
                        "type":'success',
                        "message":'Record updated successfully.'
                       });
                     eventToast.fire();                 
                }
                helper.dataInit(component, event, helper);
            });
            $A.enqueueAction(action);
        } else {
            helper.showToast('Error', 'Data invalid');
        }
    },
    cancelEdit : function(component, event, helper) {
        var leadRecord = component.get("v.leadrecord");
        leadRecord.editMode = false;
        component.set( "v.leadrecord", leadRecord);
        helper.dataInit(component, event, helper);
    },
    handlerconvertLead : function(component,event,helper) {
        let button = event.getSource();
    	button.set('v.disabled',true);
        var action = component.get('c.convertLead');
        action.setParams({
            "recordId" : component.get("v.recordId"),
        });
        action.setCallback(this, function(response) {
            
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                button.set('v.disabled', false);
                var apiResponse = response.getReturnValue();
                if(apiResponse.success) {
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                      "recordId": apiResponse.result.newOpportunity,
                      "slideDevName": "related"
                    });
                    navEvt.fire();
                }else {
                    var errorMsg;
                    if (Array.isArray(apiResponse.error)) {
                        errorMsg = apiResponse.error.join(', ');
                    } else if (typeof apiResponse.error === 'string') {
                        errorMsg = apiResponse.error;
                    }
                	helper.showToast('Error', errorMsg);
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