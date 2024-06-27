({
	doInit : function(component, event, helper) {
        component.set('v.recordId',component.get('v.pageReference').state.c__recordId);
        
        var actions = [
            { label: 'Show details', iconName:'utility:display_text' , name: 'show_details' }
        ];
        
        component.set('v.columns', [
            {label: 'Rule Name', fieldName: 'RuleName', type: 'text'},
            {label: 'Percent (%)', fieldName: 'Percent', type: 'number', typeAttributes: { maximumFractionDigits: '2' }},
            {label: 'Target', fieldName: 'Target', type: 'number', typeAttributes: { maximumFractionDigits: '0' }},
            {label: 'Actual', fieldName: 'Value', type: 'number', typeAttributes: { maximumFractionDigits: '0' }},            
            {label: 'Max Percent (%)', fieldName: 'MaxPercent', type: 'number', typeAttributes: { maximumFractionDigits: '2' }},
            {label: 'Actual Percent (%)', fieldName: 'ValuePercent', type: 'number', typeAttributes: { maximumFractionDigits: '2' }},
            { type: 'button-icon' ,initialWidth:10, typeAttributes: { label: 'Detail',name:'show_details', iconName:'utility:display_text', menuAlignment: 'right',iconPosition:'right' }}
        ]);
        
        component.set('v.columnsCommission', [
            {label: 'Type', fieldName: 'Name', type: 'string'},
            {label: 'Actual', fieldName: 'Value', type: 'number', typeAttributes: { maximumFractionDigits: '0' }},
            { type: 'button-icon',initialWidth:10, typeAttributes: { label: 'Detail',name:'show_details', iconName:'utility:display_text', menuAlignment: 'right' }}
        ]);       
        
        component.set('v.columnsDetail', [
            //{label: 'Rule', fieldName: 'Rule__c', type: 'text'},
            {label: 'Type',fieldName:'Label__c',type: 'text'},            
            {label: 'Amount', fieldName: 'Amount__c', type: 'number', typeAttributes: { maximumFractionDigits: '2' }},
            {label: 'Opportunity', fieldName: 'Opportunity_Link__c', type: 'url', typeAttributes: { label:{ fieldName: 'Opportunity_Name__c' },target: '_blank'}},
            {label: 'Order', fieldName: 'Order_Link__c', type: 'url', typeAttributes: { label:{ fieldName: 'Order_Name__c' },target: '_blank'}},
            {label: 'Invoice No',fieldName:'Invoice_No__c',type: 'text'},
            {label: 'Invoice Date',fieldName:'Invoice_Date__c',type: 'Date'},
            {label: 'Sales Owner',fieldName:'Sales_Owner__c',type: 'String'},
            {label: 'Monthly Task', fieldName: 'Monthly_Task_Link__c', type: 'url', typeAttributes: { label:{ fieldName: 'Monthly_Task_Name__c' },target: '_blank'}},
            {label: 'Follow Fail', fieldName: 'Follow_Fail_Link__c', type: 'url', typeAttributes: { label:{ fieldName: 'Follow_Fail_Name__c' },target: '_blank'}},
            {label: 'Order Product', fieldName: 'Order_Product_Link__c', type: 'url', typeAttributes: { label:{ fieldName: 'Order_Item_Number__c' },target: '_blank'}},
            {label: 'Roster Management', fieldName: 'Roster_Management__c', type: 'url', typeAttributes: { label:{ fieldName: 'Roster_Managements_Name__c' },target: '_blank'}},
            {label: 'Case', fieldName: 'Case__c', type: 'url', typeAttributes: { label:{ fieldName: 'Case_Name__c' },target: '_blank'}},
            {label: 'Warehouse Inventory', fieldName: 'Warehouse_Inventory__c', type: 'url', typeAttributes: { label:{ fieldName: 'Warehouse_Inventory_Name__c' },target: '_blank'}},
            {label: 'Test Ride', fieldName: 'Test_Ride_Link__c', type: 'url', typeAttributes: { label:{ fieldName: 'Test_Ride_Name__c' },target: '_blank'}},
            {label: 'Stock History', fieldName: 'Stock_History_Link__c', type: 'url', typeAttributes: { label:{ fieldName: 'Stock_History_Name__c' },target: '_blank'}}
        ]);
        
        
        
		component.set('v.showSpinner', true);  
        var action = component.get("c.getData");
        action.setParams({
            recordId:component.get('v.recordId')
        });
        action.setCallback(this,function(response){
            var response = response.getReturnValue();
            
            if(response.success)
            {
                //console.log(response.result['Employee']);
                //console.log(response.result['EmployeeDetail']);
                //console.log(response.result['Commission']);
                
                component.set('v.employee',response.result['Employee']);  
                component.set('v.data',response.result['EmployeeDetail']);  
                component.set('v.dataCommission',response.result['Commission']);  
                               
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
                console.log(row.Id);
                component.set('v.showSpinner', true);  
                var action = component.get("c.getDataDetail");
                action.setParams({
                    recordId:component.get('v.recordId'),
                    rule : row.Id
                });
                action.setCallback(this,function(response){
                    var response = response.getReturnValue();
                    if(response.success)
                    {
                        //component.set('v.openModal',true);
                        component.set('v.dataDetail',response.result);  
                        
                        console.log(response.result);
                        
                        component.set('v.dataDetailExist',true);
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
                
                break;
        }
    },
    
    handleCommissionRowAction: function (component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        switch (action.name) {
            case 'show_details':
                console.log(row.Name);
                component.set('v.showSpinner', true);  
                var action = component.get("c.getCommissionDataDetail");
                action.setParams({
                    recordId:component.get('v.recordId'),
                    commissionType : row.Name
                });
                action.setCallback(this,function(response){
                    var response = response.getReturnValue();
                    if(response.success)
                    {
                        //component.set('v.openModal',true);
                        component.set('v.dataDetail',response.result);  
                        
                        console.log(response.result);
                        
                        component.set('v.dataDetailExist',true);
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
                
                break;
        }
    },

    showModel: function (component, event, helper) {
       	component.set('v.openModal',true);
    },
    closeModel: function (component, event, helper) {
       	component.set('v.openModal',false);
    },
    
})