({
    doInit: function(component, event, helper) {        
        helper.dataInit(component, event);
    },
    //handle Industry Picklist Selection
    handleOnChange : function(component, event, helper) {
        let schedule = component.get("v.reschedule");
        let currentDate = new Date();
        currentDate.setDate(currentDate.getDate() +  Number(schedule.dueDate));
        schedule.datereschedule = currentDate.toISOString().slice(0, 10);
        component.set("v.reschedule", schedule);
    },
	submitScoreAction : function(component, event, helper) {
        var isValidate = true;
        var note = component.find('note');
        var duedate = component.find('duedate');
        var noteVal = component.find('note').get('v.value');        
        var duedateVal = component.find('duedate').get('v.value');
        
        if($A.util.isUndefinedOrNull(noteVal) || $A.util.isUndefined(noteVal) || $A.util.isEmpty(noteVal)){
            note.set("v.errors",[{message:'Note is required'}]);
            isValidate = false;
        }else{
            note.set("v.errors",null);
        }        
        
        if($A.util.isUndefinedOrNull(duedateVal) || $A.util.isUndefined(duedateVal) || $A.util.isEmpty(duedateVal) || duedateVal <= 0){
           	$A.util.addClass(component.find("fteError"),"show");
            isValidate = false;
        }else{
             $A.util.removeClass(component.find("fteError"), "show");
        }
        
        if(isValidate) {
			helper.createTaskHelper(component, event, helper);
        }
	},
})