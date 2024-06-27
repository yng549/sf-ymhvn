({
	validateZaloForm: function(component) {
        var validContact = true;
         // Show error messages if required fields are blank
        var allValid = component.find('zaloField').reduce(function (validFields, inputCmp) {
            inputCmp.showHelpMessageIfInvalid();
            return validFields && inputCmp.get('v.validity').valid;
        }, true); 
        if (allValid) {
            // Verify we have an recordZaloUser to attach it to
            var recordZaloUser = component.get("v.recordZaloUser");
            if($A.util.isEmpty(recordZaloUser)) {
                validContact = false;
                console.log("Quick action context doesn't have a valid recordZaloUser.");
            }
            return(validContact);
        }  
    },
    showToast : function(component, title, message, type) {
        component.find('notificationsLibrary').showToast({
            "title": title,
            "message": message,
            "variant": type,
            "mode": "sticky"
        });
    }, 
})