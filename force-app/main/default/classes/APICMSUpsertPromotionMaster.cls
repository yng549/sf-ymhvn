/*******************************************************************************
 ** Class Name: APICMSUpsertPromotionMaster
 ** Description: Call to CMS upsert promotion
 ** Test Class : ButtonSyncPromotionToCMSTest
 ** Version: 1.0
 ** Created By: THL
 ** Modified By:
 *******************************************************************************/
public class APICMSUpsertPromotionMaster {
    public class CreatePromoQueue implements Queueable, Database.AllowsCallouts {
     	List<Id> promotionIds;
        public CreatePromoQueue(List<Id> promotionIds){
            this.promotionIds = promotionIds;
        }
        public void execute(QueueableContext context) {
            if(promotionIds.isEmpty()) return;
            
            try {
                List<Id> queryPromoIds = promotionIds;
                Map<String, Schema.SObjectField> promoFieldMap = Promotion__c.sObjectType.getDescribe().fields.getMap();
                List<string> promoSelectFields = new List<String>(promoFieldMap.keySet());
              	promoSelectFields.add('RecordType.Name');
                String promoSoql = 'SELECT ' + String.join(promoSelectFields, ',');
                promoSoql += ' FROM Promotion__c';
                promoSoql += ' WHERE Id IN :promotionIds';            
                List<Promotion__c> promos = Database.query(promoSoql); 
                if(promos.isEmpty()){
                    return;
                }
                Map<String, Schema.SObjectField> promoItemFieldMap = Promotion_Item__c.sObjectType.getDescribe().fields.getMap();  
                List<string> promoItemSelectFields = new List<String>(promoItemFieldMap.keySet());
                promoItemSelectFields.add('RecordType.Name');
                promoItemSelectFields.add('(SELECT Id, Product__r.RecordType.Name, Discount__c ,List_Price__c, Product__r.ProductCode, Product__r.Color_Code__c,Sale_Price__c, Discount_Amount__c, Is_Show_Sumary__c, Promotion_Desc__c FROM Promotion_Productts__r)');
                promoItemSelectFields.add('(SELECT Id, Name, Name_VN__c FROM Promotion_Item_Packs__r WHERE Is_Public_Web__c = TRUE)');
                String promoItemSoql = 'SELECT ' + String.join(promoItemSelectFields, ',');
                promoItemSoql += ' FROM Promotion_Item__c';
                promoItemSoql += ' WHERE Promotion__c IN :queryPromoIds'; 
                List<Promotion_Item__c> promoItems = Database.query(promoItemSoql);
                Map<Id, List<Promotion_Item__c>> mapPromoToItem = new Map<Id, List<Promotion_Item__c>>();
                for(Promotion_Item__c pi : promoItems){
                    if(!mapPromoToItem.containsKey(pi.Promotion__c)){
                        mapPromoToItem.put(pi.Promotion__c, new List<Promotion_Item__c>());
                    }
                    mapPromoToItem.get(pi.Promotion__c).add(pi);
                }
                List<Promotion__c> updatedPromos = new List<Promotion__c>();
                List<DevLog__c> logs = new List<DevLog__c>();
                
                for(Promotion__c p : promos){
                    string strMessage = '';
                    HttpResponse response = new HttpResponse();
                    Promotion__c updatePromo = new Promotion__c(Id = p.Id);
                    try {
                        if(!mapPromoToItem.containsKey(p.Id)) continue;
                        List<Promotion_Item__c> lstPromoItem = mapPromoToItem.get(p.Id);
                        Data req = new Data();
                        Promotion promoRequestData = convertPromoToItemCMS(p, lstPromoItem);
                        req.promotion_data.add(promoRequestData);
                        string jsondata = JSON.serialize(req);
                        // separate source promotions that callout correctly Endpoint.
                        response = p.Source__c == 'Revzone' ? requestApiCMS(jsondata) : requestWorkShopCMS(jsondata);
                        
                        ResponseBody result = (ResponseBody)JSON.deserialize(response.getBody(), ResponseBody.class);
                        if(response.getStatusCode() == 200){
                            if(result.status == '200'){
                                updatePromo.Is_Sync_CMS__c = true;
                                updatePromo.CMS_Log__c = 'Success';
                            } 
                        } else {
                            updatePromo.CMS_Log__c = result.status + '_' + result.message;
                        } 
                        logError('APICMSUpsertPromotionMaster.CreatePromoQueue', strMessage, trimErrorMessage(response.getBody()), p.Id, p.Name, p.Id);
                    } catch(Exception e){
                        updatePromo.CMS_Log__c = e.getMessage();
                        strMessage = e.getMessage() + ' - ' + e.getLineNumber();
                        logError('APICMSUpsertPromotionMaster.CreatePromoQueue', strMessage, trimErrorMessage(response.getBody()), p.Id, p.Name, null);
                    }
                    updatedPromos.add(updatePromo);
                }
                update updatedPromos;
            } catch(Exception e){
                String strMessage = e.getMessage() + ' - ' + e.getLineNumber();
                logError('APICMSUpsertPromotionMaster.CreatePromoQueue', e.getMessage() + ' - ' + e.getLineNumber(), JSON.serialize(promotionIds), null, '', null);
            }
        }
    }
    public static Promotion convertPromoToItemCMS(Promotion__c promo, List<Promotion_Item__c> promoItems) {
        Promotion data = new Promotion();
        data.promotion_id = promo.Id;
        data.promotion_code = promo.Promotion_Code__c;
        data.promotion_name = promo.Name;
        List<PromotionItem> lstPromoItems = new List<PromotionItem>();
        for (Promotion_Item__c pi : promoItems) {
            PromotionItem piDto = new PromotionItem();
            piDto.sf_record_type = pi.RecordType.Name;
            piDto.promotion_item_id = pi.Id;
            piDto.active = pi.Active__c ? '1' : '0';
            piDto.promotion_type = promo.RecordType.Name;
            piDto.promotion_item_code = pi.Promotion_Item_Code__c;
            piDto.promotion_item_name = pi.Name;
            piDto.valid_from = String.valueOf(pi.Valid_from__c);
            piDto.valid_to = String.valueOf(pi.Valid_to__c);
            piDto.voucher_amount = pi.Voucher_Amount__c != null ? pi.Voucher_Amount__c : 0 ;
            piDto.description = pi.Description__c;
            piDto.published = pi.Public_Access__c ? 1 : 0;
            piDto.discount = pi.Discount__c != null ? pi.Discount__c : 0;
            List<PromotionPack> lstPromoPacks = new List<PromotionPack>();
            List<PromotionProduct> lstPromoProducts = new List<PromotionProduct>();
            for (Promotion_Item_Pack__c pack : pi.Promotion_Item_Packs__r){
                PromotionPack promopack =  new PromotionPack();
                promopack.item_pack_id = pack.Id;
                promopack.promotion_pack_code = pack.Name;
                promopack.promotion_pack_name = pack.Name_VN__c;
                lstPromoPacks.add(promopack);
            }
            for (Promotion_Product__c product : pi.Promotion_Productts__r){
                PromotionProduct promoproduct =  new PromotionProduct();
                promoproduct.record_type = product.Product__r.RecordType.Name;
                promoproduct.product_code = product.Product__r.ProductCode;
                promoproduct.color_code = product.Product__r.Color_Code__c;
                
                promoproduct.amount = product.Discount_Amount__c  != null ? product.Discount_Amount__c  : 0;
                promoproduct.discount = product.Discount__c != null ? product.Discount__c : 0;
                
                promoproduct.list_price = product.List_Price__c != null ? product.List_Price__c : 0;
                promoproduct.sale_price = product.Sale_Price__c != null ? product.Sale_Price__c : 0;
                promoproduct.isShowSumary = product.Is_Show_Sumary__c ? 1 : 0;
                promoproduct.PromotionDesc = product.Promotion_Desc__c != null ? product.Promotion_Desc__c : '';
                lstPromoProducts.add(promoproduct);
            }
            piDto.promotion_pack_data  = lstPromoPacks;
            piDto.promotion_product_data  = lstPromoProducts;
            lstPromoItems.add(piDto);
        }
        data.promotion_item_data = lstPromoItems;
        return data;
    }
    private static String trimErrorMessage(String errorMessage){        
        if(errorMessage.length() > 30000){
            errorMessage = errorMessage.substring(0, 30000);
        }
        return errorMessage;
    }
    private static void logError(String function, String message, String input, String output, String url, Id idPromo){
        DevLog__c log = new DevLog__c(
            Function__c = function,
            Url__c = url,
            Input__c = input,
            Output__c = output,
            Message__c = message,
            Promotion__c = idPromo
        );
        insert log;
    }
    public class ResponseBody {
        public string status {
            get;
            set;
        }
        public string message {
            get;
            set;
        }
    }
    public static HttpResponse requestApiCMS(String reqBody) {
		Http http = new Http();
		HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:API_CMS/updatePromotion');
		request.setMethod('POST');
		request.setHeader('Content-Type', 'application/json');
        request.setBody(reqBody);
        request.setTimeout(120000);
        return http.send(request);
	}
    public static HttpResponse requestWorkShopCMS(String reqBody) {
		Http http = new Http();
		HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:CMS_WORKSHOP/updatePromotion');
        
		request.setMethod('POST');
        request.setHeader('Authorization', '{!$Credential.Password}');
		request.setHeader('Content-Type', 'application/json');
        request.setBody(reqBody);
        request.setTimeout(120000);
        return http.send(request);
	}
    public class Data {
        public List<Promotion> promotion_data;
        public Data() {
            this.promotion_data = new List<Promotion>();
        }
    }
    public class Promotion {
        public string promotion_id;
        public string promotion_code;
        public string promotion_name;
        public List<PromotionItem> promotion_item_data;
    }
    public class PromotionItem {
        public string sf_record_type;
        public string active;
        public Integer published;
        public string promotion_type;
        public string promotion_item_id;
        public string promotion_item_code;
        public string promotion_item_name;
        public string valid_from;
        public string valid_to;
        public Decimal voucher_amount;
        public string description;
        public Decimal discount;
        public List<PromotionPack> promotion_pack_data;
        public List<PromotionProduct> promotion_product_data;
    }
    public class PromotionPack {
        public string item_pack_id;
        public string promotion_pack_code;
        public string promotion_pack_name;
    }
    public class PromotionProduct {
        public string record_type;
        public string product_code;
        public string color_code;
        public decimal discount;
        public decimal amount;
        public decimal list_price;
        public decimal sale_price;
        public decimal isShowSumary;
        public string PromotionDesc;
    }
}