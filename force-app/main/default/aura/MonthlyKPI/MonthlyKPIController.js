({
    doInit : function(component, event, helper) {
        
        var today = new Date();
        var monthDigit = today.getMonth() + 1;

        //helper.buildTableBody(component);
        component.set('v.currentYear',today.getFullYear());
        component.find("selectMonth").set("v.value", monthDigit);
        component.find("selectYear").set("v.value", today.getFullYear());
        
        var actions = [
            { label: 'Show details', iconName:'utility:display_text' , name: 'show_details' }
        ];
        
        component.set('v.columns', [
            {label: 'Name', fieldName: 'Record_Link__c', type: 'url', typeAttributes: { label:{ fieldName: 'Name' },target: '_blank'}},
            {label: 'Role', fieldName: 'Role__c', type: 'text'},
            {label: 'Manager', fieldName: 'Manager_Name__c', type: 'text'},
            {label: 'Team', fieldName: 'Team__c', type: 'text'},
            {label: 'Staff Code', fieldName: 'Staff_Code__c', type: 'text'},
            {label: 'KPI', fieldName: 'KPI__c', type: 'number' , typeAttributes: { maximumFractionDigits: '2' }},
            {label: 'KPI Rate', fieldName: 'KPI_Rate__c', type: 'number', typeAttributes: { maximumFractionDigits: '2' }},
            {label: 'Total Commission', fieldName: 'Commission__c', type: 'number', typeAttributes: { maximumFractionDigits: '0' }},
            {label: 'Actual Commission', fieldName: 'Total_Commission__c', type: 'number', typeAttributes: { maximumFractionDigits: '0' }},
            { type: 'button-icon' ,initialWidth:10, typeAttributes: { label: 'Detail',name:'show_details', iconName:'utility:display_text', menuAlignment: 'right' }}
        ]);
        
        var action = component.get("c.getDODL");
        action.setParams({
        });
        action.setCallback(this,function(response){
            var response = response.getReturnValue();
            if(response.success)
            { 
                component.set('v.listDodl',response.result);  
            }
            else
            {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "message": response.error
                });
                toastEvent.fire();
            }         
             component.set('v.showSpinner', false); 
        });       
        $A.enqueueAction(action);   
	},
    
	startGetData : function(component, event, helper) {
        component.set('v.showSpinner', true);  
        var action = component.get("c.getData");
        action.setParams({
            selectedMonth: component.get('v.selectedMonth'),
            selectedYear: component.get('v.selectedYear'),
            selectedTeam: component.get('v.selectedTeam'),
            selectedDODL: component.get('v.selectedDODL')
        });
        action.setCallback(this,function(response){
            var response = response.getReturnValue();
            if(response.success)
            {
                component.set('v.data',response.result);  
                
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
    
     handleRowAction: function (component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        switch (action.name) {
            case 'show_details':
                //console.log(row.Id);
                const navService = component.find('navService');
                              
                var evt = $A.get("e.force:navigateToComponent");
                evt.setParams({
                    componentDef : "c:MonthKPIEmployeeDetail",
                    componentAttributes: {
                        recordId : row.Id
                    }
                });
                //evt.fire();
                
                //$A.get("e.force:navigateToComponent").setParams({componentDef: "c:MonthKPIEmployeeDetail", attributes: {"recordId": "row.Id"}}).fire();
                
                var pageReference = {
                    type: 'standard__component',
                    attributes: {
                        componentName: 'c__MonthKPIEmployeeDetail',
                        pageName: 'EmployeeDetail'
                    },    
                    state: {
                        'c__recordId': row.Id   
                    }
                };               
                
                const handleUrl = (url) => {
                    //alert(url);
                    //console.log(url);
                    window.open(url);
                };
                    const handleError = (error) => {
                    console.log(error);
                };
                    
                navService.generateUrl(pageReference).then(handleUrl, handleError);
                
                break;
        }
     }
})