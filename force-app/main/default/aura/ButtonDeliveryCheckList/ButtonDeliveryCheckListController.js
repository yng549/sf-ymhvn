({
    openPDF : function(component, event, helper){
        var recordId = component.get('v.recordId');
        var urlPDF = '/apex/VFP_DeliveryCheckList?Id='+recordId;
        component.set("v.fullUrl", urlPDF);
    },
    handleClose : function(component, event, helper){
        $A.get("e.force:closeQuickAction").fire()
    }
})