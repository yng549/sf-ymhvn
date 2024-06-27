({
	doInit : function(component, event, helper) {
        
        var today = new Date();
		var monthDigit = today.getMonth() + 1;
        //helper.buildTableBody(component);

        component.set('v.currentYear',today.getFullYear());
        component.find("selectMonth").set("v.value", monthDigit);
        component.find("selectYear").set("v.value", today.getFullYear());
        
            
	},
    
    startGetData: function(component,event,helper)
    {
        component.set('v.showSpinner', true);
        component.set('v.dataExist',false);
        
        var action = component.get("c.getData");
        action.setParams({
            selectedMonth: component.get('v.selectedMonth'),
            selectedYear: component.get('v.selectedYear')
        });
        action.setCallback(this,function(response){
            var response = response.getReturnValue();

            if(response.success)
            {
                console.log('Response success');
                component.set('v.data',response.result);  
                
                let result = response.result;
                
                component.set('v.SaleAM',result['Sales AM/Manager']);
                //console.log('Sale AM : DONE');
                //console.log(response.result['Sales AM/Manager']);
                component.set('v.SaleSuper',result['Sales Supevisor']);
                console.log('Sale Super : DONE');
                //console.log(result['Sales Supevisor'][0]['listChild']);
                component.set('v.ServiceAM',response.result['Service AM/Sup']);
                //console.log('Service AM : DONE');
                component.set('v.ServiceCon',response.result['Service Consultant']);
                //console.log('Service Con : DONE');
                component.set('v.ServiceTech',response.result['Service Technician']);
                //console.log('Service Tech : DONE');
                component.set('v.PCASuper',response.result['PCA Supervisor']);
                //console.log('PCA PCASuper : DONE');
                component.set('v.PCACon',response.result['PCA Sales Consultant']);       
                //console.log('PCA PCACon : DONE');             
                                              
                component.set('v.dataExist',true);
                component.set('v.showSpinner', false);               
            }
            else
            {
                component.set('v.showSpinner', false);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "message": response.error
                });
                toastEvent.fire();
            }            
        });       
        $A.enqueueAction(action);
    },
    
    save: function(component, event, helper)
    {
        component.set('v.showSpinner', true);      

		console.log('Save');        

        var action = component.get("c.saveDataKPI");
        action.setParams({
            SaleAM: component.get('v.SaleAM'),
            SaleSuper: JSON.stringify(component.get('v.SaleSuper')),
            ServiceAM: component.get('v.ServiceAM'),
            ServiceCon: component.get('v.ServiceCon'),
            ServiceTech: component.get('v.ServiceTech'),
            PCASuper: JSON.stringify(component.get('v.PCASuper'))
        });
        action.setCallback(this,function(response){
            var response = response.getReturnValue();
            
            if(response.success)
            {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": 'Save Success',
                    "type":'success'
                });
                toastEvent.fire();            
            }
            else
            {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "message": response.error,
                    "type":'error'
                });
                toastEvent.fire();
            }
            component.set('v.showSpinner', false);
        });
        $A.enqueueAction(action);
	}
})