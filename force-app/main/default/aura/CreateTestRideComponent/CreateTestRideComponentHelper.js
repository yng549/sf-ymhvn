({
    init : function(component) {
        var action = component.get('c.getInitialData');
        action.setParams({
            recordId : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set("v.apirespone", result.result);
            }else if (state === "ERROR") {
                this.showToast('error', response.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    
    searchRecordsHelper : function(component, event, helper, selectedRecords) {       
		$A.util.removeClass(component.find("Spinner"), "slds-hide");
        component.set('v.message', '');
        component.set('v.recordsList', []);
        var idproduct = component.get("v.apirespone").product.Id;
        var searchString = component.get('v.searchString');
    	var action = component.get('c.fetchRecords');
        action.setParams({
            'objectName' : component.get('v.objectName'),
            'filterField' : component.get('v.fieldName'),
            'searchString' : searchString,
            'values' : JSON.stringify(selectedRecords),
            'idproductDefault' : idproduct
        });
        action.setCallback(this,function(response){
        	var result = response.getReturnValue();
        	if(response.getState() === 'SUCCESS') {
    			if(result.length > 0) {
    				// To check if value attribute is prepopulated or not
					if( $A.util.isEmpty(selectedRecords) ) {
                        var selectedRcrds = component.get('v.selectedRecords') || [];
                        for(var i = 0; i < result.length; i++) {
                            if(selectedRcrds.includes(result[i].value))
                                result[i].isSelected = true;
                        }
                        component.set('v.recordsList', result);        
					} else {
                        component.set('v.selectedDataObj', result);
					}
    			} else {
    				component.set('v.message', "No Records Found for '" + searchString + '"');
    			}
        	} else {
               this.showToast('error', response.getError()[0].message);
            }
            // To open the drop down list of records
            if( $A.util.isEmpty(selectedRecords) )
                $A.util.addClass(component.find('resultsDiv'),'slds-is-open');
        	$A.util.addClass(component.find("Spinner"), "slds-hide");
        });
        $A.enqueueAction(action);
	},
    /*
	* closeQAModal アクションモーダル閉じる
    *
    */
    closeQAModal : function(){
        $A.get("e.force:closeQuickAction").fire();
    },
    showToast : function(type, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "message": message,
            type: type
        });
        toastEvent.fire();
    },
    navigateToPrintView: function (component, printUrl) {
        debugger;
        this.closeQAModal();
        const navService = component.find("navService");
        navService.navigate({
          type: "standard__webPage",
          attributes: {
            url: printUrl
          }
    });
  },
})