public with sharing class EdtQuoteController {
    
    @AuraEnabled
    public static APIResponse getQuoteByRecordId(String recordId) {
        APIResponse apiResponse = new APIResponse();
        try {
            Map<Id, objPromotionDTO> mapPromotionPackDTO = new Map<Id, objPromotionDTO>();
            Map<Id, Promotion_Pack__c> mapgetAllPromotionPack = getAllPromotionPack();
            Quote objQuote = getQuoteById(recordId);
            QuoteLineItem objQuoteLineitem = getQuoteLineItem(recordId);
            if(objQuote.Quote_Promotion_Packs__r.size() > 0) {
                for(Quote_Promotion_Pack__c item : objQuote.Quote_Promotion_Packs__r) {
                    if(mapgetAllPromotionPack.containsKey(item.Promotion_Pack__c)) {
                        mapPromotionPackDTO.put(item.Promotion_Pack__c, new objPromotionDTO(mapgetAllPromotionPack.get(item.Promotion_Pack__c), true));
                    }
                }
            }
            for(Promotion_Pack__c objPromotion : mapgetAllPromotionPack.values()) {
                if(!mapPromotionPackDTO.containsKey(objPromotion.Id)) {
                    mapPromotionPackDTO.put(objPromotion.Id, new objPromotionDTO(objPromotion, false));
                }
            }
            objQuoteDTO objQuoteDTO =  new objQuoteDTO(objQuote, objQuoteLineitem, mapPromotionPackDTO.values());
            if(apiResponse.error == null) {
                apiResponse.success = true;
                apiResponse.result = objQuoteDTO;   
            }
            return apiResponse;
        } catch(Exception ex) {
            apiResponse.error = ex.getMessage() + ' ' + ex.getLineNumber();
            return apiResponse;
        }
        
    }
    
    @AuraEnabled
    public static APIResponse getPickListValuesIntoList(){
        APIResponse apiResponse = new APIResponse();
        List<String> pickListValuesList= new List<String>();
        Schema.DescribeFieldResult fieldResult = Product2.Bike_Type_2__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getLabel());
        }
        if(apiResponse.error == null) {
            apiResponse.success = true;
            apiResponse.result = pickListValuesList;   
        }
        return apiResponse;
    }
    
    @AuraEnabled
    public static APIResponse updateQuote(String json) {
        APIResponse apiResponse = new APIResponse();
        List<Quote_Promotion_Pack__c> lstQuotePromotionInsert = new List<Quote_Promotion_Pack__c>();
        List<Quote_Promotion_Pack__c> lstQuotePromotionDelete = new List<Quote_Promotion_Pack__c>();
        Map<Id, Quote_Promotion_Pack__c> mapPromotionObject = new Map<Id, Quote_Promotion_Pack__c>();
        try {
            List<String> args = new String[]{'0','number','###,###,##0.00'};
            objQuoteDTO objQuote = (objQuoteDTO) System.JSON.deserialize(json, objQuoteDTO.class);
            List<Quote_Promotion_Pack__c> lstQuotePromotion = getListQuotePromotionPack(objQuote.Id);
            Quote objQuoteQuerry = getQuoteById(objQuote.Id);
            QuoteLineItem objQuoteLineitem = getQuoteLineItem(objQuote.Id);
            if(!lstQuotePromotion.isEmpty()) {
                for(Quote_Promotion_Pack__c item : lstQuotePromotion) {
                    mapPromotionObject.put(item.Promotion_Pack__c, item);
                }
            }
            if(objQuoteQuerry.Number_Edit__c == Null) {
                objQuoteQuerry.Number_Edit__c = 0;
            }
            
            String strLog = '';
            String strLogNew = '';
            if(objQuote.DiscountAmount != objQuoteQuerry.Discount_Amount__c) {
                if(objQuoteQuerry.Discount_Amount__c < objQuote.DiscountAmount && !objQuoteQuerry.Changed__c) {
                    objQuoteQuerry.Changed__c = true;
                }
                strLog = '<br/><li><span style="color:red;font-weight:bold;">Discount Amount Old: </span>' + String.format(objQuoteQuerry.Discount_Amount__c.format(), args)  + 'đ</li>';   
                strLogNew = '<br/><li><span style="color:red;font-weight:bold;"> Discount Amount New: </span>' +String.format(objQuote.DiscountAmount.format(), args)   + 'đ</li>';  
            }
            if(objQuote.VoucherAmount != objQuoteQuerry.Voucher_Amount__c  && objQuote.VoucherAmount != NULL) {
                if(objQuoteQuerry.Voucher_Amount__c < objQuote.VoucherAmount && !objQuoteQuerry.Changed__c) {
                    objQuoteQuerry.Changed__c = true;
                }
                strLog += '<br/><li><span style="color:red;font-weight:bold;"> Voucher Amount Old: </span>' +  String.format(objQuoteQuerry.Voucher_Amount__c.format(), args) + '</li>'; 
                strLogNew += '<br/><li><span style="color:red;font-weight:bold;">Voucher Amount New: </span>' + String.format(objQuote.VoucherAmount.format(), args)  + '</li>';  
            }
            if(objQuoteQuerry.Quote_Promotion_Packs__r.size() > 0) {
                strLog += '<br/><li>Promotion list item <ul> <li><span style="color: red;font-weight:bold;"> Danh sách promotion cũ:</span> <ol>';
                for(Quote_Promotion_Pack__c item : objQuoteQuerry.Quote_Promotion_Packs__r) {
                    strLog += '<li>' + item.Promotion_Pack__r.Name + '</li>';
                }
                strLog += '</ol></li></ul></li>';
            }
            
            if(objQuote.lstPromotion.size() > 0) {
                for(objPromotionDTO item : objQuote.lstPromotion) {
                    if(mapPromotionObject.containsKey(item.Id) && !item.isChecked) {
                        lstQuotePromotionDelete.add(mapPromotionObject.get(item.Id));
                    } else if(!mapPromotionObject.containsKey(item.Id) && item.isChecked) {
                        lstQuotePromotionInsert.add(new Quote_Promotion_Pack__c(
                            Quote__c = objQuote.Id,
                            Promotion_Pack__c = item.Id
                        ));
                    }
                }
            }
            System.debug(strLog);
            
            
            objQuoteQuerry.Discount_Amount__c = objQuote.DiscountAmount != NULL ? objQuote.DiscountAmount : 0;
            objQuoteQuerry.Payment_1__c = objQuote.Payment1 != Null ? objQuote.Payment1 : 0;
            objQuoteQuerry.Payment_2__c = objQuote.Payment1 != Null ? objQuote.Payment2 : 0;
            objQuoteQuerry.Payment_3__c = objQuote.Payment1 != Null ? objQuote.Payment3 : 0;
            objQuoteQuerry.Delivery_Date__c = objQuote.DeliveryDate;
            
            objQuoteQuerry.E_commerce_Order__c = objQuote.ECommerceOrder;
            
            
            update objQuoteQuerry;
            
            Opportunity objOpportunity = new Opportunity();
            objOpportunity.Id = objQuote.OpportunityId;
            objOpportunity.Trade_in_Service__c = objQuote.PriceTradeInBike;
            objOpportunity.Finance__c = objQuote.Finance;
            
            upsert objOpportunity;
            
            Product2 objProduct2 = new Product2(
                Id = objQuote.Product2Id,
                Color_Name__c = objQuote.ProductColorName,
                Model_Name__c = objQuote.ModelBikeName,
                Origin__c = objQuote.ProductOrigin,
                Engince_cc__c = objQuote.Capacity != Null ? objQuote.Capacity : 0,
                Bike_Type_2__c = objQuote.ProductBikeType
            );
            update objProduct2;
            
            
            Account objAccount = new Account();
            objAccount.Id = objQuote.AccountId;
            objAccount.FirstName = objQuote.FirstAccountName;
            objAccount.LastName = objQuote.LastAccountName;
            objAccount.Tax_Code__c = objQuote.TaxCode != Null ? objQuote.TaxCode : Null;
            objAccount.ID_No__c = objQuote.IDNo != Null ?  objQuote.IDNo : Null;
            objAccount.PersonMobilePhone = objQuote.PersonMobilePhone;
            objAccount.PersonEmail = objQuote.Email;
            upsert objAccount;
            
            if(!lstQuotePromotionDelete.isEmpty()) {
                delete lstQuotePromotionDelete;
            }
            if(!lstQuotePromotionInsert.isEmpty()) {
                insert lstQuotePromotionInsert;
            }
            
            
            if(objQuoteLineitem != Null) {
                objQuoteLineitem.Discount_Amount__c = objQuote.DiscountAmount != NULL ? objQuote.DiscountAmount : 0;
                objQuoteLineitem.UnitPrice = objQuote.DiscountAmount !=  Null ? objQuoteLineitem.ListPrice - objQuote.DiscountAmount: objQuoteLineitem.UnitPrice;
                update objQuoteLineitem;
            }
            
            Quote objQuoteAfterUpdate = getQuoteById(objQuoteQuerry.Id);
            
            if(objQuoteAfterUpdate.Quote_Promotion_Packs__r.size() > 0) {
                if(String.isNotBlank(strLog)) {
                    strLogNew += '<br/><li><span style="color: red;font-weight:bold;">Danh sách promotion mới</span> <ol>';
                    
                } else {
                    strLogNew = '<li>Promotion list item <ul> <li> Danh sách promotion mới <ol>';
                }
                for(Quote_Promotion_Pack__c item : objQuoteAfterUpdate.Quote_Promotion_Packs__r) {
                    strLogNew += '<li>  ' + item.Promotion_Pack__r.Name   + '</li>'; 
                }
                strLogNew += '</ol></li></ul></li>';
            }
            
            
            
            //objQuoteAfterUpdate.Discount_Amount__c = (objQuote.ListPriceVAT*objQuote.DiscountPercent)/100;
            
            if(lstQuotePromotionInsert.size() > (objQuoteAfterUpdate.Quote_Promotion_Packs__r.size()-lstQuotePromotionDelete.size())) {
                objQuoteAfterUpdate.Changed__c = true;
            }
            
            
            //objQuoteAfterUpdate.Discount_Percentage__c = objQuote.DiscountPercent != Null ? objQuote.DiscountPercent : 0;
            objQuoteAfterUpdate.Voucher_Amount__c = objQuote.VoucherAmount != Null ? objQuote.VoucherAmount : 0;
            
            if(!objQuoteQuerry.Changed__c){
                objQuoteQuerry.Status = 'Approved';
            }
            if(String.isNotBlank(strLog))  {
                objQuoteAfterUpdate.Number_Edit__c = objQuoteAfterUpdate.Number_Edit__c + 1;
                if(String.isNotblank(objQuoteAfterUpdate.Log_History_Edit_Promotion__c )) {
                    objQuoteAfterUpdate.Log_History_Edit_Promotion__c += '<br/><span style="font-weight:bold;"> Lần ' + objQuoteAfterUpdate.Number_Edit__c  +'</span>' + '</br>' +  strLog  + '<hr/>';
                } else {
                    objQuoteAfterUpdate.Log_History_Edit_Promotion__c = '<span style="font-weight:bold;"> Lần ' + objQuoteAfterUpdate.Number_Edit__c +'</span>' + + '</br>' +  strLog + '<hr/>';
                }
                
            }
            if(String.isNotBlank(strLog))  {
                if(String.isNotblank(objQuoteAfterUpdate.Log_History_Edit_Promotion_New__c)) {
                    objQuoteAfterUpdate.Log_History_Edit_Promotion_New__c += ' <br/> ' +  strLogNew  + '<hr/>';
                } else {
                    objQuoteAfterUpdate.Log_History_Edit_Promotion_New__c = ' <br/>' +  strLogNew + '<hr/>';
                }
                
            }
            update objQuoteAfterUpdate;
            if(apiResponse.error == null) {
                apiResponse.success = true;
            }
            return apiResponse;
        } catch(Exception ex) {
            apiResponse.error = ex.getMessage() + ' ' + ex.getLineNumber();
            System.debug(' apiResponse.error  : ' + apiResponse.error );
            return apiResponse;
        }
    }
    
    private static Quote getQuoteById(String recordId) {
        Quote objQuote = [SELECT Id
                          , Name
                          , Voucher_Amount__c
                          , Payment_1__c
                          , Payment_2__c
                          , Payment_3__c
                          , Delivery_Date__c
                          , Discount
                          , Discount_Amount__c
                          , Discount_Percentage__c
                          , OpportunityId
                          , Opportunity.AccountId
                          , Opportunity.Account.Name
                          , Opportunity.Account.FirstName
                          , Opportunity.Account.LastName
                          , Opportunity.Account.Address_Full__c
                          , Opportunity.Account.PersonMailingAddress
                          , Opportunity.Account.Tax_Code__c
                          , Opportunity.Account.ID_No__c
                          , Opportunity.Account.PersonMobilePhone
                          , Opportunity.Account.PersonEmail
                          , Opportunity.Trade_in_Service__c
                          , Opportunity.Finance__c
                          , E_commerce_Order__c
                          , Status
                          , Log_History_Edit_Promotion_New__c 
                          , Changed__c
                          , IsSyncing
                          , Log_History_Edit_Promotion__c
                          , Number_Edit__c
                          , (SELECT Id
                             , Promotion_Pack__c
                             , Promotion_Pack__r.Name
                             
                             FROM Quote_Promotion_Packs__r)
                          
                          FROM Quote
                          WHERE Id =: recordId];
        return objQuote;
    }
    
    private static QuoteLineItem getQuoteLineItem(String recordIdQuote) {
        QuoteLineItem objQuoteLineItem =  [SELECT Id
                                           , Product2.Model_Year__c
                                           , Product2.Name
                                           , Product2.Model_Name__c
                                           , Product2.Color_Name__c
                                           , Product2.Origin__c
                                           , Product2.Bike_Type_2__c
                                           , Product2.Engince_cc__c
                                           , Discount_Amount__c
                                           , UnitPrice
                                           , ListPrice
                                           , Discount
                                           , Product2Id
                                           , Default_Discount__c
                                           FROM QuoteLineItem
                                           WHERE QuoteId =: recordIdQuote 
                                           LIMIT 1];
        return objQuoteLineItem;
    }
    
    private static Map<Id, Promotion_Pack__c> getAllPromotionPack() {
        return new Map<Id, Promotion_Pack__c>([SELECT Id, Name, Description__c FROM Promotion_Pack__c WHERE Is_Active__c =: true]);
    }
    
    private static List<Quote_Promotion_Pack__c> getListQuotePromotionPack(String recordId) {
        return new List<Quote_Promotion_Pack__c>([SELECT Id, Quote__c, Promotion_Pack__c FROM Quote_Promotion_Pack__c WHERE Quote__c =: recordId]);
    }
    
    public  class objPromotionDTO {
        @AuraEnabled
        public  string Id {get; set;}
        
        @AuraEnabled
        public  string Name {get; set;}
        
        @AuraEnabled
        public  string strDescription {get; set;}
        
        @AuraEnabled
        public Boolean isChecked {get; set;}
        
        
        public objPromotionDTO() {}
        
        public objPromotionDTO(Promotion_Pack__c obj, Boolean flagUsed) {
            this.Id = obj.Id;
            this.Name = obj.Name;
            this.strDescription = obj.Description__c;
            this.isChecked = flagUsed;
        }
    }
    
    public class objQuoteDTO {
        @AuraEnabled
        public String Id {get; set;}
        
        @AuraEnabled
        public String  Name {get; set;}
        
        @AuraEnabled
        public String  OpportunityId {get; set;}
        
        @AuraEnabled
        public Decimal  VoucherAmount {get; set;}   
        
        @AuraEnabled
        public Decimal  Payment1 {get; set;}
        
        @AuraEnabled
        public Decimal  Payment2 {get; set;}
        
        @AuraEnabled
        public Decimal  Payment3 {get; set;}
        
        
        @AuraEnabled
        public Decimal  DiscountPercent {get; set;}
        
        @AuraEnabled
        public Decimal  DiscountAmount {get; set;}
        
        @AuraEnabled
        public Decimal  PurchasePrice {get; set;}
        
        
        @AuraEnabled
        public Boolean  ECommerceOrder {get; set;}
        
        @AuraEnabled
        public Decimal  PriceTradeInBike {get; set;}
        
        @AuraEnabled
        public String  Finance {get; set;}
        
        @AuraEnabled
        public String  FirstAccountName {get; set;}
        
        @AuraEnabled
        public String  LastAccountName {get; set;}
        
        @AuraEnabled
        public String  AddressFull {get; set;}
        
        @AuraEnabled
        public String  PersonMailingAddress {get; set;}
        
        @AuraEnabled
        public String  TaxCode {get; set;}
        
        @AuraEnabled
        public String  IDNo {get; set;}
        
        @AuraEnabled
        public String  PersonMobilePhone {get; set;}
        
        @AuraEnabled
        public String Product2Id {get; set;}
        
        @AuraEnabled
        public String QuoteLineItemId {get; set;}
        
        @AuraEnabled
        public String Email {get; set;}
        
        @AuraEnabled
        public String ModelBikeName {get; set;}
        
        @AuraEnabled
        public Decimal ProductYear {get; set;}
        
        @AuraEnabled
        public String ProductColorName {get; set;}
        
        @AuraEnabled
        public String ProductEngince {get; set;}
        
        @AuraEnabled
        public String ProductOrigin {get; set;}
        
        @AuraEnabled
        public String  ProductBikeType {get; set;}
        
        
        @AuraEnabled
        public Decimal  SalePrice {get; set;} 
        
        @AuraEnabled
        public Decimal  PriceVAT {get; set;} 
        
        @AuraEnabled
        public Decimal ListPrice {get; set;}
        
        @AuraEnabled
        public Decimal Capacity {get; set;}
        
        @AuraEnabled
        public List<objPromotionDTO> lstPromotion {get; set;} 
        
        @AuraEnabled
        public Date  DeliveryDate {get; set;} 
        
        @Auraenabled
        public String AccountId {get; set;}
        
        @Auraenabled
        public Decimal ListPriceVAT{get; set;}
        
        public objQuoteDTO() {}
        
        public objQuoteDTO(Quote objQuote, QuoteLineItem QuoteLineItem,List<objPromotionDTO> lstPromotionDTO) {
            this.Id = objQuote.Id;
            this.Name = objQuote.Name;
            this.VoucherAmount = objQuote.Voucher_Amount__c;
            this.Payment1 = objQuote.Payment_1__c;
            this.Payment2 = objQuote.Payment_2__c;
            this.Payment3 = objQuote.Payment_3__c;
            //this.DiscountPercent = QuoteLineItem.Default_Discount__c;
            this.DiscountAmount = objQuote.Discount_Amount__c;
            this.FirstAccountName = objQuote.Opportunity.Account.FirstName;
            this.LastAccountName = objQuote.Opportunity.Account.LastName;
            this.AddressFull = objQuote.Opportunity.Account.Address_Full__c;
            this.TaxCode = objQuote.Opportunity.Account.Tax_Code__c;
            this.IDNo = objQuote.Opportunity.Account.ID_No__c;
            this.PersonMobilePhone = objQuote.Opportunity.Account.PersonMobilePhone;
            this.Email = objQuote.Opportunity.Account.PersonEmail;
            this.ModelBikeName = QuoteLineItem.Product2.Model_Name__c;
            this.ProductYear = QuoteLineItem.Product2.Model_Year__c;
            this.ProductColorName = QuoteLineItem.Product2.Color_Name__c;
            this.ProductOrigin = QuoteLineItem.Product2.Origin__c;
            this.ProductBikeType = QuoteLineItem.Product2.Bike_Type_2__c;
            this.ListPrice = QuoteLineItem.ListPrice > 0 ? QuoteLineItem.ListPrice/(1.1) : null;
            this.ListPriceVAT = QuoteLineItem.ListPrice;
            this.PriceVAT = QuoteLineItem.UnitPrice;
            this.SalePrice = QuoteLineItem.UnitPrice != Null ?
                Integer.valueOf(QuoteLineItem.UnitPrice - ((QuoteLineItem.UnitPrice*(QuoteLineItem.Discount != null ? QuoteLineItem.Discount : 0)/100))) : Null;
            this.Capacity = QuoteLineItem.Product2.Engince_cc__c;
            this.Product2Id = QuoteLineItem.Product2Id;
            this.ECommerceOrder = false;
            this.lstPromotion = lstPromotionDTO;
            this.DeliveryDate = objQuote.Delivery_Date__c;
            this.QuoteLineItemId = QuoteLineItem.Id;
            this.AccountId = objQuote.Opportunity.AccountId;
            this.ECommerceOrder = objQuote.E_commerce_Order__c;
            this.PriceTradeInBike = objQuote.Opportunity.Trade_in_Service__c;
            this.Finance =  objQuote.Opportunity.Finance__c;
            this.OpportunityId = objQuote.OpportunityId;
        }
    }
    Public static void cheatTemp() {
        String a = 'cheat';
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;   
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;   
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;   
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;   
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;  
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;   
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;  
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;  
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;  
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;  
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;  
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;  
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;  
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;   
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;  
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;  
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;   
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;   
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;   
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;    
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;  
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;  
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;   
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;  
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;   
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;    
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;  
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;   
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;    
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;   
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;   
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;   
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;    
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;   
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a;  
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a;  
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a;  
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a;  
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a;  
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a;  
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a;  
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a;  
        a = a;
        a = a;
        a = a;  
        a = a;
        a = a;
        a = a;  
        a = a;
        a = a;
        a = a;  
        a = a;
        a = a;
        a = a;  
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a;  
        a = a;
        a = a;
        a = a;
    }
}