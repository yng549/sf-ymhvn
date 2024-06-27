({
    doinit: function(component, event, helper) {
        helper.getProfileNameUser(component, event);
        helper.getObjectCase(component, event);
        helper.getPicklistValues(component, event);
    },

    CaseSave : function(component, event, helper) {
        helper.saveCase(component, event);
    },
    cancle : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
    //handle Industry Picklist Selection
    handleOnChange : function(component, event, helper) {
        var industry = component.get("v.objCase.Asset.Inventory_Status__c");
    }
})