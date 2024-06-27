({
	doInit: function(component, event, helper) {
        var currentYear = new Date().getFullYear();
        var yearOptions = [];
        // Tạo một danh sách các năm, ví dụ từ năm 2000 đến năm hiện tại
        for (var i = currentYear; i >= 2021; i--) {
            yearOptions.push(i.toString());
        }
        component.set("v.yearOptions", yearOptions);
        component.set("v.selectedYear", currentYear);
    },
    doSearch : function(component, event, helper) {
    	helper.executeBatch(component, event, helper);
	},
})