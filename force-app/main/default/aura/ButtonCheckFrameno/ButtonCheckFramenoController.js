({
	promiseChaining : function(component, event, helper) {
        debugger;
        var getinit = component.get("c.getInitialData");
        getinit.setParams( {
            "recordId": component.get("v.recordId"),
        });
        helper.serverSideCall(component, getinit).then(
            function(res) {
                if(res.success) {
                    var checkFrameNo = component.get("c.checkFrameNoDMS");
                    checkFrameNo.setParams( {
                        "datainit": res.result.assetInfo,
                    });
                    return helper.serverSideCall(component, checkFrameNo);
                }else {
                    helper.showToast("error",  res.error[0]);
                    return;
                }
            }
        ).then(
            function(res) {
                if(res.success) {
                    debugger;
                    component.set("v.message", res.result);
                }else {
                    helper.showToast("error",  res.error[0]);
                    return;
                }
            }
        )
        .catch(
            function(error) {
                var messageerr;
                if (JSON.parse(error.message) instanceof Array && JSON.parse(JSON.parse(error.message)[0]).arg !== 'undefined') {
                    messageerr = JSON.parse(JSON.parse(error.message)[0]).arg;
                    helper.showToast("error", messageerr);
                }else {
                    helper.showToast("error", error.message);
                }
            }
        );
    },
})