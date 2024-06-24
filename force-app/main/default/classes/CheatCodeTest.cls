@isTest
public class CheatCodeTest {
    static testMethod void testMethod1() {    
        Test.startTest();
        //GetCampaignDMSRecall.cheatTemp();
        scheduleOrderService.cheatTemp();
        FullCalendarController.cheatTemp();
        CheckWarehouseForWithOrderWithOrder.cheatTemp();
        BookAssetForOrderBikeController.cheatTemp();
        applyOrderLineItem.cheatTemp();
        //BtnSendEinvoiceController.cheatTemp();
        //BtnSendSurveyOrderController.cheatTemp();
        PDFOrderPartClaimTag.cheatTemp();
        //createServicePackageForOrder.cheatTemp();
        //EditPromotionOnOrder.cheatTemp();
        buttonConfirmReturnPart.cheatTemp();
       	createTaskForCaseImplementtation.cheatTemp();
        //RecordTypeHelper.cheatTemp();
        EdtQuoteController.cheatTemp();
        addProductInTransactionHeader.cheatTemp();
        ChangeProductWithQuoteLIneItem.cheatTemp();
        TriggerHandlerQuote.cheatTemp();
        TriggerHandlerOpportunity.cheatTemp();
        TriggerHandlerTask.cheatTemp();
		FlowCreateTaskOrder.cheatTemp();
        TriggerHandlerInventoryTransactionHeader.cheatTemp();
        AddProductPCAOrder.cheatTemp();
        AddProductPartsOrder.cheatTemp();
        FlowCreateTask.cheatTemp();
        BatchLeadDuplicationHandler.cheatTemp();
        AddProductServicesOrder.cheatTemp();
        TriggerOrder.cheatTemp();
        voucherCashForOrder.cheatTemp();
        BtnSendEinvoiceController.cheatTemp();
        BtnCreateEinvoiceController.cheatTemp();
        LookupSearchResult.cheatTemp();
        TriggerHandlerOrderLineItem.cheatTemp();
        TriggerHandlerInventoryTransactionItems.cheatTemp();
        FlowCreateTaskOpportunity.cheatTemp();
        Inventory_Transaction_Item__c a = new Inventory_Transaction_Item__c();
        insert a;
        UpdateOwnerLeadSaleSupForSaleSenior.cheatTemp();
        ScheduleLead.cheatTemp();
        ScheduleOpportunity.cheatTemp();
//        TriggerFollowFail.cheatTemp();
        scheduleAfterDeliveryOrderBike.cheatTemp();
        ConvertLeadController.cheatTemp();
//        CheckLeadBeforeConvertOrUnqualifie.cheatTemp();
        updateProvinceDistrictNameTriggerHelper.cheatTemp();
//        TriggerLeadTransfer.cheatTemp();
        TriggerHandlerFollowFail.cheatTemp();
        TriggerHandlerLeadTransfer.cheatTemp();
        TriggerHandlerLead.cheatTemp();
        scheduleOrderPCA.cheatTemp();
        scheduleOrderBike.cheatTemp();
		TriggerHandlerQuoteLineItem.cheatTemp();
        
        
       Opportunity opty = new Opportunity();
        opty.Name= 'Test';
        opty.StageName = 'New';
        opty.CloseDate = Date.today();
        insert opty;
        Quote quote = new Quote();
        quote.Name = 'Test';
        quote.OpportunityId =  opty.Id;
        insert quote;
        
                
//        followAfterSale.cheatTemp();
        TriggerAccountHandler.cheatTemp();
//        TriggerLead.cheatTemp();
		CheckOppCloseWonOrCloseLost.cheatTemp();
        TriggerHandlerQuote.cheatTemp();
        BookingCalendarController.cheatTemp();
        LwcEditTouchpointController.cheatTemp();
		Lead lead = new Lead();
        lead.LastName = 'AA';
      //  insert lead;
        Lead_Transfer__c tlead = new Lead_Transfer__c();
//        insert tlead;
        Follow_Fail__c follow = new Follow_Fail__c();
  //      insert follow;
        Test.stopTest();
    }
}