({
    onInit : function(component, event, helper) {
        console.log('aa');
        debugger;
        component.set("v.isLoading", true);
        window.setTimeout(
            function() { 
                component.set("v.isLoading", false);
                var surveyEnpoint = component.get("v.orderRC");
                window.location.href = surveyEnpoint.Account.Language__c  == 'Vietnamese' ? surveyEnpoint.Link_Survey_VN__c : surveyEnpoint.Link_Survey_EN__c;
            }, 
            2000
        );
        
    }
})