public class BtnSendSurveyOrderController {
    
    // meta data chưa dùng tới
    static Survey_Order__mdt apiSetting { 
        get {
            if (apiSetting == null) {                
                Survey_Order__mdt[] settings = [
                    SELECT 
                        MasterLabel, DeveloperName, Sales__c, Service__c, PCA__c,
                    	Sales_VN__c,Service_VN__c,PCA_VN__c,Is_Send__c
                    FROM Survey_Order__mdt
                    WHERE DeveloperName = 'Default'
                ];              
                if(!settings.isEmpty()){
                    //system.debug(settings[0]);
                    apiSetting = settings[0];
                } else {
                    if(!Test.isRunningTest()){
                        //throw new SmsClass.SmsBrandNameException('Please setup a default API setting');
                    } else {
                        Survey_Order__mdt setting = new Survey_Order__mdt();
                        setting.DeveloperName = 'Default';
                        setting.Sales__c = 'test';
                        setting.Service__c = 'test';
                        setting.PCA__c = 'test';
                        apiSetting = setting;
                    }
                }   
            }
            return apiSetting;
        }
        set {
        }
    }
    
    public static void getSurveyUrl(Order order,String surveyName)
    {
        //system.debug(surveyName);
        string endPointVN = '';
        string endPointEN = '';
        
        
        /*Map<String, Schema.SObjectField> orderFieldMap = Order.sObjectType.getDescribe().fields.getMap();
        List<string> orderSelectFields = new List<String>(orderFieldMap.keySet());   
        orderSelectFields.add('Account.Name');
        orderSelectFields.add('Account.Phone');
        orderSelectFields.add('Account.PersonMobilePhone');        
        orderSelectFields.add('DO_DL__r.Name');
        orderSelectFields.add('Asset__r.Product_Name__c');    
        orderSelectFields.add('Account.Gender__c');    
        orderSelectFields.add('Account.DOB__pc');   
        orderSelectFields.add('Account.Address_Full__c');   
        orderSelectFields.add('Asset__r.Frame_Number__c');   
        orderSelectFields.add('Asset__r.Engine_No__c');   
        orderSelectFields.add('Do_DL__r.DO_DL_Code__c');    
        orderSelectFields.add('Account.Sub_Mobile__pc');          
        String orderSoql = 'SELECT ' + String.join(orderSelectFields, ',');
        orderSoql += ' FROM Order';
        orderSoql += ' WHERE Id = :orderId'; 
        Order order = Database.query(orderSoql); */
        
        
        string eventType = '';
        string eventTypeVN = '';
        if(surveyName == '1') // Sale
        {
            endPointVN = apiSetting.Sales_VN__c;
            endPointEN = apiSetting.Sales__c;
            eventType = 'Sales';
            eventTypeVN = 'Bán hàng';
        }
        else if( surveyName == '2' || surveyName == '4') // Service
        {
            endPointVN = apiSetting.Service_VN__c;
            endPointEN = apiSetting.Service__c;
            eventType = 'Service';
            eventTypeVN = 'Dịch vụ';
        }
        else if( surveyName == '3') // PCA
        {
            endPointVN = apiSetting.PCA_VN__c;
            endPointEN = apiSetting.PCA__c;
            eventType = 'PCA';
            eventTypeVN = 'Phụ tùng, Quần áo và Phụ kiện';
        }
        
        
        //Customer name // Account.Name
        //Address // Address_Full__c
        //Phone number 1 
        //Email // Email__c
        //Dealer name // DO_DL__r.Name
        //Model name // Asset__r.Product_Code__c	
        //Event type
        //Event date // Today
        
        //endPoint = 'https://ymvn.formstack.com/forms/form_sales';
        String endPointData = '';
        endPointData += '?Order_Id='+order.Id;
        endPointData += '&Account_Dealer='+order.DO_DL__c;
        endPointData += '&Account_Personal='+order.AccountId;
        if(surveyName == '4')
        {
            Date completeDate = order.Complete_Date__c != null ? order.Complete_Date__c : Date.today();
            endPointData += '&VAT_Date='+ completeDate ;
        }
        else
        {
            endPointData += '&VAT_Date='+order.Invoice_Date__c ;
        }
        if(order.DO_DL__r.Name != null)endPointData += '&Dealer_name='+order.DO_DL__r.Name.replaceAll(' ', '%20');
        if(order.Do_DL__r.DO_DL_Code__c != null)endPointData += '&Dealer_code='+order.Do_DL__r.DO_DL_Code__c.replaceAll(' ', '%20');
        if(order.Account.Name != null) endPointData += '&Customer_Name='+order.Account.Name.replaceAll(' ', '%20');
        if(order.Account.PersonMobilePhone != null) endPointData += '&Phone_number_1='+order.Account.PersonMobilePhone;
        if(order.Account.Sub_Mobile__pc != null) endPointData += '&Phone_number_2='+order.Account.Sub_Mobile__pc;
        if(order.Email__c != null)endPointData += '&Email='+order.Email__c;
        if(order.Account.Address_Full__c != null) endPointData += '&Address='+order.Account.Address_Full__c.replaceAll(' ', '%20');
        //if(order.Account.Gender__c != null)endPointData += '&Gender='+order.Account.Gender__c;
        if(order.Account.DOB__pc != null)endPointData += '&DOB='+order.Account.DOB__pc;
        if(order.Asset__r.Product_Name__c != null)endPointData += '&Model_Name='+order.Asset__r.Product_Name__c.replaceAll(' ', '%20');
        if(order.Asset__r.Frame_Number__c != null)endPointData += '&Vin_No='+order.Asset__r.Frame_Number__c;
        if(order.Asset__r.Engine_No__c != null)endPointData += '&Engine_No='+order.Asset__r.Engine_No__c;
        endPointData += '&Event_Type='+eventType;
        endPointData += '&Event_Date='+String.valueOf(Date.today()) ;      
        if(order.Order_Number__c != null)endPointData += '&SO_Number='+order.Order_Number__c;
        endPointData += '&Respond_Date='+String.valueOf(Date.today()) ;
        //endPoint +=
        
        
        String endPointDataVN = '';
        endPointDataVN += '?Order_Id='+order.Id;
        endPointDataVN += '&Account_Dealer='+order.DO_DL__c;
        endPointDataVN += '&Account_Personal='+order.AccountId;
        if(surveyName == '4')
        {
            Date completeDate = order.Complete_Date__c != null ? order.Complete_Date__c : Date.today();
         	endPointDataVN += '&Ngày_mua_hàng='+completeDate;   
        }
        else
        {
            endPointDataVN += '&Ngày_mua_hàng='+order.Invoice_Date__c;
        }       
        if(order.DO_DL__r.Name != null)endPointDataVN += '&Tên_Đại_lý='+order.DO_DL__r.Name.replaceAll(' ', '%20');
        if(order.Do_DL__r.DO_DL_Code__c != null)endPointDataVN += '&Dealer_code='+order.Do_DL__r.DO_DL_Code__c.replaceAll(' ', '%20');
        if(order.Account.Name != null) endPointDataVN += '&Họ_và_tên_Khách_hàng='+order.Account.Name.replaceAll(' ', '%20');
        if(order.Account.PersonMobilePhone != null) endPointDataVN += '&Số_điện_thoại_1='+order.Account.PersonMobilePhone;
        if(order.Account.Sub_Mobile__pc != null) endPointDataVN += '&Số_điện_thoại_2='+order.Account.Sub_Mobile__pc;
        if(order.Email__c != null)endPointDataVN += '&Email='+order.Email__c;
        if(order.Account.Address_Full__c != null) endPointDataVN += '&Địa_chỉ='+order.Account.Address_Full__c.replaceAll(' ', '%20');
        //if(order.Account.Gender__c != null)endPointData += '&Gender='+order.Account.Gender__c;
        if(order.Account.DOB__pc != null)endPointDataVN += '&Ngày_sinh='+order.Account.DOB__pc;
        if(order.Asset__r.Product_Name__c != null)endPointDataVN += '&Tên_mẫu_xe='+order.Asset__r.Product_Name__c.replaceAll(' ', '%20');
        if(order.Asset__r.Frame_Number__c != null)endPointDataVN += '&Số_khung='+order.Asset__r.Frame_Number__c;
        if(order.Asset__r.Engine_No__c != null)endPointDataVN += '&Số_máy='+order.Asset__r.Engine_No__c;
        endPointDataVN += '&Loại_sự_kiện='+eventTypeVN;
        endPointDataVN += '&Event_Date='+String.valueOf(Date.today()) ;      
        if(order.Order_Number__c != null)endPointDataVN += '&Số_Đơn_mua_hàng='+order.Order_Number__c;
        endPointDataVN += '&Respond_Date='+String.valueOf(Date.today()) ;
        
        endPointEN += endPointData;
        endPointVN += endPointDataVN;
        
        order.Link_Survey_EN__c = endPointEN;
        order.Link_Survey_VN__c = endPointVN;
        
    }
    
	@AuraEnabled
    public static ApiResponse sendSurvey(String orderId,String surveyName)
    {
        ApiResponse api = new ApiResponse();
        string endPointVN = '';
        string endPointEN = '';
        
        
        if(apiSetting == null)
        {
            api.error = 'Please setup survey meta data';
            return api;
        }
        
        Map<String, Schema.SObjectField> orderFieldMap = Order.sObjectType.getDescribe().fields.getMap();
        List<string> orderSelectFields = new List<String>(orderFieldMap.keySet());   
        orderSelectFields.add('Account.Name');
        orderSelectFields.add('Account.Phone');
        orderSelectFields.add('Account.PersonMobilePhone');        
        orderSelectFields.add('DO_DL__r.Name');
        orderSelectFields.add('Asset__r.Product_Name__c');    
        orderSelectFields.add('Account.Gender__c');    
        orderSelectFields.add('Account.DOB__pc');   
        orderSelectFields.add('Account.Address_Full__c');   
        orderSelectFields.add('Asset__r.Frame_Number__c');   
        orderSelectFields.add('Asset__r.Engine_No__c');   
        orderSelectFields.add('Do_DL__r.DO_DL_Code__c');    
        orderSelectFields.add('Account.Sub_Mobile__pc');          
        String orderSoql = 'SELECT ' + String.join(orderSelectFields, ',');
        orderSoql += ' FROM Order';
        orderSoql += ' WHERE Id = :orderId'; 
        Order order = Database.query(orderSoql); 
        
        
        system.debug(order);
        if(order == null)
        {
            api.error = 'No order found';
            return api;
        }
        
        string eventType = '';
        string eventTypeVN = '';
        if(surveyName == '1') // Sale
        {
            endPointVN = apiSetting.Sales_VN__c;
            endPointEN = apiSetting.Sales__c;
            eventType = 'Sales';
            eventTypeVN = 'Bán hàng';
        }
        else if( surveyName == '2' || surveyName == '4') // Service
        {
            endPointVN = apiSetting.Service_VN__c;
            endPointEN = apiSetting.Service__c;
            eventType = 'Service';
            eventTypeVN = 'Dịch vụ';
        }
        else if( surveyName == '3') // PCA
        {
            endPointVN = apiSetting.PCA_VN__c;
            endPointEN = apiSetting.PCA__c;
            eventType = 'PCA';
            eventTypeVN = 'Phụ tùng, Quần áo và Phụ kiện';
        }
        
        if(endPointVN == '' && endPointEN == '')
        {
            api.error = 'Please choose survey';
            return api;
        }
        
        //Customer name // Account.Name
		//Address // Address_Full__c
		//Phone number 1 
		//Email // Email__c
		//Dealer name // DO_DL__r.Name
		//Model name // Asset__r.Product_Code__c	
		//Event type
		//Event date // Today
  
        //endPoint = 'https://ymvn.formstack.com/forms/form_sales';
        String endPointData = '';
        endPointData += '?Order_Id='+order.Id;
        endPointData += '&Account_Dealer='+order.DO_DL__c;
        endPointData += '&Account_Personal='+order.AccountId;
        if(surveyName == '4')
        {
            Date completeDate = order.Complete_Date__c != null ? order.Complete_Date__c : Date.today();
            endPointData += '&VAT_Date='+ completeDate ;
        }
        else
        {
            endPointData += '&VAT_Date='+order.Invoice_Date__c ;
        }
        if(order.DO_DL__r.Name != null)endPointData += '&Dealer_name='+order.DO_DL__r.Name.replaceAll(' ', '%20');
        if(order.Do_DL__r.DO_DL_Code__c != null)endPointData += '&Dealer_code='+order.Do_DL__r.DO_DL_Code__c.replaceAll(' ', '%20');
        if(order.Account.Name != null) endPointData += '&Customer_Name='+order.Account.Name.replaceAll(' ', '%20');
        if(order.Account.PersonMobilePhone != null) endPointData += '&Phone_number_1='+order.Account.PersonMobilePhone;
        if(order.Account.Sub_Mobile__pc != null) endPointData += '&Phone_number_2='+order.Account.Sub_Mobile__pc;
        if(order.Email__c != null)endPointData += '&Email='+order.Email__c;
        if(order.Account.Address_Full__c != null) endPointData += '&Address='+order.Account.Address_Full__c.replaceAll(' ', '%20');
        //if(order.Account.Gender__c != null)endPointData += '&Gender='+order.Account.Gender__c;
        if(order.Account.DOB__pc != null)endPointData += '&DOB='+order.Account.DOB__pc;
        if(order.Asset__r.Product_Name__c != null)endPointData += '&Model_Name='+order.Asset__r.Product_Name__c.replaceAll(' ', '%20');
        if(order.Asset__r.Frame_Number__c != null)endPointData += '&Vin_No='+order.Asset__r.Frame_Number__c;
        if(order.Asset__r.Engine_No__c != null)endPointData += '&Engine_No='+order.Asset__r.Engine_No__c;
        endPointData += '&Event_Type='+eventType;
        endPointData += '&Event_Date='+String.valueOf(Date.today()) ;      
        if(order.Order_Number__c != null)endPointData += '&SO_Number='+order.Order_Number__c;
        endPointData += '&Respond_Date='+String.valueOf(Date.today()) ;
        //endPoint +=
                    
        
        String endPointDataVN = '';
        endPointDataVN += '?Order_Id='+order.Id;
        endPointDataVN += '&Account_Dealer='+order.DO_DL__c;
        endPointDataVN += '&Account_Personal='+order.AccountId;
        if(surveyName == '4')
        {
            Date completeDate = order.Complete_Date__c != null ? order.Complete_Date__c : Date.today();
            endPointDataVN += '&Ngày_mua_hàng='+completeDate;   
        }
        else
        {
            endPointDataVN += '&Ngày_mua_hàng='+order.Invoice_Date__c;
        }    
        if(order.DO_DL__r.Name != null)endPointDataVN += '&Tên_Đại_lý='+order.DO_DL__r.Name.replaceAll(' ', '%20');
        if(order.Do_DL__r.DO_DL_Code__c != null)endPointDataVN += '&Dealer_code='+order.Do_DL__r.DO_DL_Code__c.replaceAll(' ', '%20');
        if(order.Account.Name != null) endPointDataVN += '&Họ_và_tên_Khách_hàng='+order.Account.Name.replaceAll(' ', '%20');
        if(order.Account.PersonMobilePhone != null) endPointDataVN += '&Số_điện_thoại_1='+order.Account.PersonMobilePhone;
        if(order.Account.Sub_Mobile__pc != null) endPointDataVN += '&Số_điện_thoại_2='+order.Account.Sub_Mobile__pc;
        if(order.Email__c != null)endPointDataVN += '&Email='+order.Email__c;
        if(order.Account.Address_Full__c != null) endPointDataVN += '&Địa_chỉ='+order.Account.Address_Full__c.replaceAll(' ', '%20');
        //if(order.Account.Gender__c != null)endPointData += '&Gender='+order.Account.Gender__c;
        if(order.Account.DOB__pc != null)endPointDataVN += '&Ngày_sinh='+order.Account.DOB__pc;
        if(order.Asset__r.Product_Name__c != null)endPointDataVN += '&Tên_mẫu_xe='+order.Asset__r.Product_Name__c.replaceAll(' ', '%20');
        if(order.Asset__r.Frame_Number__c != null)endPointDataVN += '&Số_khung='+order.Asset__r.Frame_Number__c;
        if(order.Asset__r.Engine_No__c != null)endPointDataVN += '&Số_máy='+order.Asset__r.Engine_No__c;
        endPointDataVN += '&Loại_sự_kiện='+eventTypeVN;
        endPointDataVN += '&Event_Date='+String.valueOf(Date.today()) ;      
        if(order.Order_Number__c != null)endPointDataVN += '&Số_Đơn_mua_hàng='+order.Order_Number__c;
        endPointDataVN += '&Respond_Date='+String.valueOf(Date.today()) ;
        
        endPointEN += endPointData;
        endPointVN += endPointDataVN;
        
        order.Link_Survey_EN__c = endPointEN;
        order.Link_Survey_VN__c = endPointVN;
        
        if(apiSetting.Is_Send__c || Test.isRunningTest())
        {
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.toAddresses = new String[] { order.Email__c };
                //message.toAddresses = new String[] { 'phuc.le@itk.com.vn' };
                //message.optOutPolicy = 'FILTER';
                message.setCharset('UTF-8');
            message.subject = 'Yamaha VietNam Survey';
            String body = '<a>You have new survey from Yamaha Viet Nam . </a><br><a href=' + endPointVN + '>Vietnamese</a><br><a href=' + endPointEN + '>English</a>';
            message.setHtmlBody(body);
            Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
                Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
            
            if (results[0].success) {
                api.result = 'Send email success';
                api.success = true;
                System.debug('The email was sent successfully.');
            } else {
                api.error = results[0].errors[0].message;
                System.debug('The email failed to send: ' + results[0].errors[0].message);
            }
        }
        else
        {
            api.success = true;
            api.result = 'Create survey link success';
        }
        
        update order;
        
        return api;
    }
    
}