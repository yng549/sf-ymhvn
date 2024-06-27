({
  init: function (cmp, event, helper) {
    console.log("invoked, " + cmp.get("v.recordId"));
  },

  cancelQuickAction: function (cmp, e) {
    $A.get("e.force:closeQuickAction").fire();
  },
  refresh :function(cmp,event,helper){
      helper.refreshLead(cmp);
  }
});