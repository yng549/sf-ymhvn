({
	executeBatch : function (component, event, helper){
        var action = component.get("c.getSaleReportDashboard");
        action.setParams({
            yearCon : component.get("v.selectedYear"),
            docode : component.get("v.selectedDO"),
            isScheduled : false
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "success",
                    "title": "Success!",
                    "message": "The Job has been successfully initiated. The system will send an email to know more details"
                });
                toastEvent.fire();

                if (state === "SUCCESS"){
                    var interval = setInterval($A.getCallback(function () {
                        var jobStatus = component.get("c.getBatchJobStatus");
                        if(jobStatus != null){
                            jobStatus.setParams({ jobID : response.getReturnValue()});
                            jobStatus.setCallback(this, function(jobStatusResponse){
                                var state = jobStatus.getState();
                                if (state === "SUCCESS"){
                                    var job = jobStatusResponse.getReturnValue();

                                    component.set('v.apexJob', job);
                                    var processedPercent = 0;
                                    if(job.JobItemsProcessed != 0){
                                        processedPercent = (job.JobItemsProcessed / job.TotalJobItems) * 100;
                                    }
                                    var progress = component.get('v.progress');
                                    component.set('v.progress', progress === 100 ? clearInterval(interval) :  processedPercent);
                                    var jobFinish = false;
                                    if (job.Status === "Completed" && job.JobItemsProcessed === 0 && job.TotalJobItems === 0) {
                                        clearInterval(interval);
                                        jobFinish = true;
                                    }
                                    if (progress === 100 || jobFinish === true) {
                                        //component.set('v.buttonstate', false);
                                        debugger;
                                        var apiResponeJob = component.get("c.createDataLeadReport");
                                        apiResponeJob.setParams({
                                            jobID : job.Id
                                        });
                                        apiResponeJob.setCallback(this, function(apiRespone){
                                            debugger;
                                            var stateApi = apiRespone.getState();
                                            if (stateApi === "SUCCESS"){
                                                var apiResult = apiRespone.getReturnValue();
                                                component.set('v.salesResultMap', apiResult.result);
                                                window.setTimeout(
                                                     $A.getCallback(function() {
                                                          component.set("v.apexJob", null)
                                                     }), 2000
                                                );
                                            }
                                            else if (stateApi === "ERROR") {
                                                var toastEvent = $A.get("e.force:showToast");
                                                toastEvent.setParams({
                                                    "type": "error",
                                                    "title": "Error!",
                                                    "message": response.getError()[0].message
                                                });
                                                toastEvent.fire();
                                            }
                                        });
                                        $A.enqueueAction(apiResponeJob);
                                    }
                                }
                            });
                            $A.enqueueAction(jobStatus);
                        }
                    }), 8000);
                }
            }
            else if (state === "ERROR") {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": "Error!",
                    "message": response.getError()[0].message
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
    },
})