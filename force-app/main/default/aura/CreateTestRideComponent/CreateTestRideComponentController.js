({
	/*
	* doInit 画面初期処理
    *
    * @param component
	* @param event
	* @param helper
	*/
    doInit : function(component, event, helper) {
        $A.util.toggleClass(component.find('resultsDiv'),'slds-is-open');
        if( !$A.util.isEmpty(component.get('v.selectedRecords')) ) {
			helper.searchRecordsHelper(component, event, helper, component.get('v.selectedRecords'));
		}
        helper.init(component);
    },
     // When a keyword is entered in search box
	searchRecords : function( component, event, helper ) {
        if( !$A.util.isEmpty(component.get('v.searchString'))) {
		    helper.searchRecordsHelper(component, event, helper, []);
        } else {
            $A.util.removeClass(component.find('resultsDiv'),'slds-is-open');
        }
	},

    // When an item is selected
	selectItem : function( component, event, helper ) {
        if(!$A.util.isEmpty(event.currentTarget.id)) {
    		var recordsList = component.get('v.recordsList');
            var selectedRecords = component.get('v.selectedRecords') || [];
            var selectedDataObj = component.get('v.selectedDataObj') || [];
    		var index = recordsList.findIndex(x => x.value === event.currentTarget.id)
            if(index != -1) {
                recordsList[index].isSelected = recordsList[index].isSelected === true ? false : true;
                if(selectedRecords.includes(recordsList[index].value)) {
                    selectedRecords.splice(selectedRecords.indexOf(recordsList[index].value), 1);
                    var ind = selectedDataObj.findIndex(x => x.value === event.currentTarget.id)
                    if(ind != -1) {selectedDataObj.splice(ind, 1)}
                } else {
                	selectedRecords.push(recordsList[index].value);
                    selectedDataObj.push(recordsList[index]);
                }
            }
            component.set('v.recordsList', recordsList);
            component.set('v.selectedRecords', selectedRecords);
            component.set('v.selectedDataObj', selectedDataObj);
        }
        $A.util.removeClass(component.find('resultsDiv'),'slds-is-open');
	},
    
    removePill : function( component, event, helper ){
        var recordId = event.getSource().get('v.name');
        var recordsList = component.get('v.recordsList');
        var selectedRecords = component.get('v.selectedRecords');
        var selectedDataObj = component.get('v.selectedDataObj');
        
        selectedRecords.splice(selectedRecords.indexOf(recordId), 1);
        var index = selectedDataObj.findIndex(x => x.value === recordId)
        if(index != -1) {
            selectedDataObj.splice(index, 1)
        }
        var ind = recordsList.findIndex(x => x.value === recordId)
        if(ind != -1) {
            recordsList[ind].isSelected = false;
        }
        component.set('v.recordsList', recordsList);
        component.set('v.selectedDataObj', selectedDataObj);
        component.set('v.selectedRecords', selectedRecords);
    },
    
    showRecords : function( component, event, helper ){
        var disabled = component.get('v.disabled');
        if(!disabled && !$A.util.isEmpty(component.get('v.recordsList')) && !$A.util.isEmpty(component.get('v.searchString'))) {
            $A.util.addClass(component.find('resultsDiv'),'slds-is-open');
        }
    },

    // To close the dropdown if clicked outside the inputbox.
    blurEvent : function( component, event, helper ){
        $A.util.removeClass(component.find('resultsDiv'),'slds-is-open');
    },
    /*
    * doSaveRecords 施行記録を保存
    *
    */
    doSaveRecords : function(component, event, helper){
        $A.util.removeClass(component.find("Spinner2"), "slds-hide");
        var saveData = component.get('v.apirespone');
        var action = component.get('c.saveRecords');
        action.setParams({
            data : saveData,
            productsTest : component.get('v.selectedRecords')
        });
       action.setCallback(this, function(response) {
          var state = response.getState();
          var apiResponse = response.getReturnValue();
          if (apiResponse.success) {
            var result = response.getReturnValue();
        	helper.navigateToPrintView(component, result.result);
          } else {
              component.set("v.errorMessage", Array.isArray(apiResponse.error) ? apiResponse.error.join("\n") : apiResponse.error);
          }
          $A.util.addClass(component.find("Spinner2"), "slds-hide");
    	});
        $A.enqueueAction(action);
    },
    removeDefaultProduct : function( component, event, helper ) {
        var productId= component.get('v.apirespone.product.Id');
        var productName= component.get('v.apirespone.product.Name');
        if (productId !=null){
            component.set("v.productId",productId);
            component.set("v.productName",productName);
            component.set("v.apirespone.product.Name",'');
            component.set("v.apirespone.product.Id",null);
        }else{
            component.set("v.apirespone.product.Name",component.get("v.productName"));
            component.set("v.apirespone.product.Id",component.get("v.productId"));
        }
     
	},
})