({
	setupColumnDetail : function(component) {
		let employee = component.get('v.employee');
        
        //if(employee.)
        component.set('v.columnsDetail', [
            {label: 'Rule Name', fieldName: 'RuleName', type: 'text'},
            {label: 'Percent', fieldName: 'Percent', type: 'text'},
            {label: 'Target', fieldName: 'Target', type: 'text'},
            {label: 'Value', fieldName: 'Value', type: 'text'},
            {label: 'Value Percent', fieldName: 'ValuePercent', type: 'text'},
            {label: 'MaxPercent', fieldName: 'MaxPercent', type: 'text'}
        ]);
	}
})