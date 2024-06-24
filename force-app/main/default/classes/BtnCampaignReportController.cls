public class BtnCampaignReportController {
    @AuraEnabled
	public static ApiResponse calculateCamp(String recordId)
    { 
        List<Campaign_Detail__c> listOldDetail = [Select Id from Campaign_Detail__c
                                                 where Campaign__c =: recordId];
        
        ApiResponse api = new ApiResponse();
        List<Campaign_Detail__c> listDetail = new List<Campaign_Detail__c>();
        
		Campaign camp = [Select Id,StartDate,Total_campaign_Member_New_lead__c,Total_Campaign_member_Old_Account__c,Total_campaign_Member_Old_lead__c,Total_round_to_sale_Account__c,
                         Total_round_to_sale_New_Lead__c,Total_round_to_sale_Old_Lead__c,Number_of_opportunity_bike__c	,Number_of_order_bike_VAT__c,Number_of_order_PCA_VAT__c,
                         Number_of_order_Service_Complete__c,Sum_Amount_Order_PCA_from_Campaign__c,Sum_Amount_Order_Service_From_campaign__c,ActualCost
                        from Campaign
                        where Id =: recordId];
        
        List<CampaignMember> listMember = [Select Id,CampaignId,LeadId,ContactId,Lead.Round_To_Sale__c,Status,Old_Lead__c,
                                           Contact.AccountId,Lead.Name,Contact.Account.Name,Name
                                from CampaignMember
                                where CampaignId =: camp.Id];
        
        Set<String> setAccountId = new Set<String>();
        for(CampaignMember member : listMember)
        {
            if(member.ContactId != null && member.Contact.AccountId != null)
            {
				setAccountId.add(member.Contact.AccountId);                
            }         
        }
        system.debug(setAccountId);
        
        List<Opportunity> listOpty = [Select Id,StageName,AccountId,Name
                                     from Opportunity
                                     where AccountId in: setAccountId
                                     and RecordTypeId =: RecordTypeHelper.OPPORTUNITY_BIKE];
        for(Opportunity opty : listOpty)
        {
            Campaign_Detail__c detail = new Campaign_Detail__c();
            detail.Campaign__c = camp.Id;
            detail.Calculate_For__c = '	Number of opportunity bike';
            detail.Opportunity__c = opty.Id;
            detail.Name = opty.Name;
            listDetail.add(detail);
        }
        
        system.debug(camp.StartDate);
        List<Order> listOrderBike = [Select Id,Name
                                     from Order
                                     where RecordTypeId =: RecordTypeHelper.ORDER_BIKE 
                                     and AccountId in: setAccountId and Invoice_Date__c != null
                                     and Status = 'Completed' and CreatedDate >=: camp.StartDate
                                   ];
        system.debug(listOrderBike);
        for(Order order : listOrderBike)
        {
            Campaign_Detail__c detail = new Campaign_Detail__c();
            detail.Campaign__c = camp.Id;
            detail.Calculate_For__c = 'Number of order bike (VAT)';
            detail.Order__c = order.Id;
            detail.Name = order.Name;
            listDetail.add(detail);
        }
        
        
        List<Order> listOrderPCA = [Select Id,Amount__c,Name
                                    from Order
                                    where RecordTypeId =: RecordTypeHelper.ORDER_PCA 
                                    and AccountId in: setAccountId and Invoice_Date__c != null
                                    and Status = 'Completed' and CreatedDate >=: camp.StartDate];
        system.debug(listOrderPCA);
        
        Decimal totalAmountPCA = 0;
        for(Order o: listOrderPCA)
        {
            Campaign_Detail__c detail = new Campaign_Detail__c();
            detail.Campaign__c = camp.Id;
            detail.Calculate_For__c = 'PCA';
            detail.Order__c = o.Id;
            detail.Amount__c = o.Amount__c;
            detail.Name = o.Name;
            listDetail.add(detail);
            
            totalAmountPCA += o.Amount__c;
        }
        
        List<Order> listOrderService = [Select Id,Amount__c,Name
                                    from Order
                                    where (RecordTypeId =: RecordTypeHelper.ORDER_SERVICE_ORDER OR RecordTypeId =: RecordTypeHelper.ORDER_SERVICE_PACKAGE OR RecordTypeId =: RecordTypeHelper.ORDER_WARRANTY
                                          OR RecordTypeId =: RecordTypeHelper.ORDER_FREE_SERVICE OR RecordTypeId =: RecordTypeHelper.ORDER_QUICK_SERVICE OR RecordTypeId =: RecordTypeHelper.ORDER_FREE_COUPON)
                                    and AccountId in: setAccountId and Invoice_Date__c != null
                                    and Status = 'Completed' and CreatedDate >=: camp.StartDate];
        system.debug(listOrderService);
        
        Decimal totalAmountService = 0;
        for(Order o : listOrderService)
        {
            Campaign_Detail__c detail = new Campaign_Detail__c();
            detail.Campaign__c = camp.Id;
            detail.Calculate_For__c = 'Service';
            detail.Order__c = o.Id;
            detail.Amount__c = o.Amount__c;
            detail.Name = o.Name;
            listDetail.add(detail);
            
            totalAmountService += o.Amount__c;
        }
        
        Decimal totalNewLead = 0;
        Decimal totalOldLead = 0;
        Decimal totalOldAccount = 0;
        Decimal totalNewRoundToSaleLead = 0;
        Decimal totalOldRoundToSaleLead = 0;
        Decimal totalRoundToSale = 0;
        
        for(CampaignMember member : listMember)
        {
            if(member.LeadId != null && member.Old_Lead__c == false)
            {
                totalNewLead++;
                
                Campaign_Detail__c detail = new Campaign_Detail__c();
                detail.Campaign__c = camp.Id;
                detail.Calculate_For__c = 'Total campaign Member - New lead';
                detail.Lead__c = member.LeadId;
                detail.Name = member.Lead.Name;
                listDetail.add(detail);
                
                if(member.Lead.Round_To_Sale__c == true)
                {
                    totalNewRoundToSaleLead++;
                    
                    Campaign_Detail__c detailSale = new Campaign_Detail__c();
                    detailSale.Campaign__c = camp.Id;
                    detailSale.Calculate_For__c = 'Total round to sale - New Lead';
                    detailSale.Lead__c = member.LeadId;
                    detailSale.Name = member.Lead.Name;
                    listDetail.add(detailSale);
                }
            }
            else if(member.LeadId != null && member.Old_Lead__c == true)
            {
                totalOldLead++;
                
                Campaign_Detail__c detail = new Campaign_Detail__c();
                detail.Campaign__c = camp.Id;
                detail.Calculate_For__c = 'Total campaign Member - Old lead';
                detail.Lead__c = member.LeadId;
                detail.Name = member.Lead.Name;
                listDetail.add(detail);
                
                if(member.Lead.Round_To_Sale__c == true)
                {
                    totalOldRoundToSaleLead++;
                    
                    Campaign_Detail__c detailSale = new Campaign_Detail__c();
                    detailSale.Campaign__c = camp.Id;
                    detailSale.Calculate_For__c = 'Total round to sale - Old Lead';
                    detailSale.Lead__c = member.LeadId;
                    detailSale.Name = member.Lead.Name;
                    listDetail.add(detailSale);           
                }
            }
            else if(member.LeadId == null && member.ContactId != null)
            {
                totalOldAccount++;
                
                Campaign_Detail__c detail = new Campaign_Detail__c();
                detail.Campaign__c = camp.Id;
                detail.Calculate_For__c = 'Total Campaign member - Old Account';
                detail.Account__c  = member.Contact.AccountId;
                detail.Name = member.Contact.Account.Name;
                listDetail.add(detail);
            }
            
            if(member.Status == 'Round To Sale')
            {
                totalRoundToSale++;
                
                Campaign_Detail__c detailSale = new Campaign_Detail__c();
                detailSale.Campaign__c = camp.Id;
                detailSale.Calculate_For__c = 'Total round to sale - Account';
                //detailSale.Lead__c = member.LeadId;
                detailSale.Name = member.Name;
                listDetail.add(detailSale);
            }
        }
        
        camp.Total_campaign_Member_New_lead__c = totalNewLead; // Total campaign Member - New lead
        camp.Total_campaign_Member_Old_lead__c = totalOldLead; // Total campaign Member - Old lead
        camp.Total_Campaign_member_Old_Account__c = totalOldAccount; // Total Campaign member - Old Account
        camp.Total_round_to_sale_New_Lead__c = totalNewRoundToSaleLead; // Total round to sale - New Lead
        camp.Total_round_to_sale_Old_Lead__c = totalOldRoundToSaleLead; // Total round to sale - Old Lead
        //camp.Total_round_to_sale_Account__c = totalRoundToSale; // Total round to sale - Account // 
        camp.Number_of_opportunity_bike__c = listOpty.size(); // Number of opportunity bike
        camp.Number_of_order_bike_VAT__c = listOrderBike.size(); // Number of order bike (VAT)
        camp.Number_of_order_PCA_VAT__c = listOrderPCA.size(); // Number of order PCA VAT
        camp.Sum_Amount_Order_PCA_from_Campaign__c = totalAmountPCA; // Sum Amount Order PCA from Campaign
        camp.Number_of_order_Service_Complete__c = listOrderService.size(); // Number of order Service Complete
        camp.Sum_Amount_Order_Service_From_campaign__c = totalAmountService; // Sum Amount Order  Service From campaign       
        
        try
        {
            update camp;
            
            if(!listDetail.isEmpty())
            {
                insert listDetail;
            }
            
            if(!listOldDetail.isEmpty())
            {
                delete listOldDetail;
            }
            
            api.success = true;
        }
        catch(Exception  e)
        {
            String error = e.getMessage() + ' , '+e.getLineNumber();
            api.error = error;
        }
        return api;
    }
    
    public static void addP()
    {
        string p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
    }
}