({
    doInit: function(component, event, helper) {
        var userId = $A.get("$SObjectType.CurrentUser.Id");
		component.find("zaloUserSiteRecordCreator").getNewRecord(
            "OpportunityTeamMember", // objectApiName
            null, // recordTypeId
            false, // skip cache?
            $A.getCallback(function() {
                component.set("v.Loading", false);
                var zaloUserOrignal = component.get("v.zaloUserOrignal");
                if(zaloUserOrignal == null) {
                   component.set("v.ShowSection", true);
                   return;
                }
                var rec = component.get("v.simpleZaloUserSite");
                rec.TeamMemberRole = 'Sales Rep';
                rec.UserId = userId;
                rec.OpportunityId = zaloUserOrignal.Id;
                rec.OpportunityAccessLevel = 'Edit';
        		component.set("v.simpleZaloUserSite", rec);
            })
        ); 
    },
    handleSaveZaloUser: function(component, event, helper) {
        if(helper.validateZaloForm(component)) {
           component.set("v.Loading", true);
           var saveData = component.get('v.simpleZaloUserSite');
           var action = component.get('c.saveRecords');
           action.setParams({
                oppmember : saveData
           });
           action.setCallback(this, function(response) {
              component.set("v.Loading", false); 
              var state = response.getState();
              var apiResponse = response.getReturnValue();
              if (apiResponse.success) {
                
                helper.showToast(component, 'SUCCESS', 'Opportunity Team member add to success', 'Successfully');
              } else {
                  component.set("v.errorMessage", Array.isArray(apiResponse.error) ? apiResponse.error.join("\n") : apiResponse.error);
              }
              $A.util.addClass(component.find("Spinner2"), "slds-hide");
            });
           $A.enqueueAction(action);
            /*component.find("zaloUserSiteRecordCreator").saveRecord(function(saveResult) {
                component.set("v.Loading", false);
                if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                    helper.showToast(component, 'SUCCESS', 'Cảm ơn Mẹ đã đăng ký thông tin!', 'Đăng Ký Thành Công!');
                    $A.get("e.force:closeQuickAction").fire();
                    
                }
                else if (saveResult.state === "INCOMPLETE") {
                    console.log("INCOMPLETE");
                }
                else if (saveResult.state === "ERROR") {
                    helper.showToast(component, 'SUCCESS', saveResult.error[0]['message'], 'Exception Error');
                    $A.get("e.force:closeQuickAction").fire();
                    console.log('Problem saving contact, error: ' + JSON.stringify(saveResult.error));
                   	         
                }
                else {
                    console.log('Unknown problem, state: ' + saveResult.state +
                                ', error: ' + JSON.stringify(saveResult.error));
                }
            });*/
        }
    }
})