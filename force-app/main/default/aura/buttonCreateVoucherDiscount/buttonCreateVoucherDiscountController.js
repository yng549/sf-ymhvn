({
    executeBatch : function (cmp){
        var action = cmp.get("c.executeBatchJob");
        var recordId = cmp.get("v.recordId");
        var quantityNumber = cmp.get("v.quantityNumber");
        action.setParams({
            "strRecordId": recordId,
            "dcmNumber": quantityNumber
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
                if (state === "SUCCESS"){
                    var interval = setInterval($A.getCallback(function () {
                        var jobStatus = cmp.get("c.getBatchJobStatus");
                        if(jobStatus != null){
                            jobStatus.setParams({ jobID : response.getReturnValue()});
                            jobStatus.setCallback(this, function(jobStatusResponse){
                                var state = jobStatus.getState();
                                if (state === "SUCCESS"){
                                    var job = jobStatusResponse.getReturnValue();
                                    cmp.set('v.apexJob',job);
                                    var processedPercent = 0;
                                    if(job.JobItemsProcessed != 0){
                                        processedPercent = (job.JobItemsProcessed / job.TotalJobItems) * 100;
                                    }
                                    var progress = cmp.get('v.progress');
                                    cmp.set('v.progress', progress === 100 ? clearInterval(interval) :  processedPercent);
                                    var numberError = cmp.get("v.apexJob.NumberOfErrors");
                                    if(numberError == 0) {
                                        cmp.set("v.quantityNumber", '0');
                                        cmp.set("v.truthy", false);

                                        var toastEvent = $A.get("e.force:showToast");
                                        toastEvent.setParams({
                                            "type": "success",
                                            "title": "Success!",
                                            "message": "The Job has been successfully initiated."
                                        });
                                        toastEvent.fire();
                                        location.reload();
                                        //$A.get("e.force:closeQuickAction").fire();
                                    }
                                }
                            });
                            $A.enqueueAction(jobStatus);
                        }
                    }), 2000);
            }
            else if (state === "ERROR") {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": "Error!",
                    "message": "An Error has occured. Please try again or contact System Administrator."
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
    },

    changeValueNumber: function(component, event, helper) {
        var numberInput = component.get("v.quantityNumber");
        if(numberInput > 0 && numberInput <= 2000) {
            component.set("v.strErrorInputNumber", '');
            component.set("v.truthy", true);
        } else if(numberInput <= 0) {
            component.set("v.truthy", false);
            component.set("v.strErrorInputNumber", 'Input value must be more than 0');
        } else if(numberInput > 2000) {
            component.set("v.truthy", false);
            component.set("v.strErrorInputNumber", 'Input value must be less than 2000');
        }
    },

    closeModal : function(cmp, evt, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
});