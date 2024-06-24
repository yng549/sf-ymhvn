public class TriggerSurveyPCAHandler {
	static Survey_PCA_Alert__mdt apiSetting { 
        get {
            if (apiSetting == null) {                
                Survey_PCA_Alert__mdt[] settings = [
                    SELECT 
                    MasterLabel, DeveloperName, Question_1__c,Question_2__c
                    FROM Survey_PCA_Alert__mdt
                    WHERE DeveloperName = 'Default'
                ];              
                if(!settings.isEmpty()){
                    //system.debug(settings[0]);
                    apiSetting = settings[0];
                } else {
                    if(!Test.isRunningTest()){
                        //throw new SmsClass.SmsBrandNameException('Please setup a default API setting');
                    } else {
                        Survey_PCA_Alert__mdt setting = new Survey_PCA_Alert__mdt();
                        setting.DeveloperName = 'Default';
                        setting.Question_1__c = 7;
                        setting.Question_2__c = 7;
                        apiSetting = setting;
                    }
                }   
            }
            return apiSetting;
        }
        set {
        }
    }
    
    public static void onBeforeInsert(List<SurveyPCA__c> listSurveyPCA)
    {
        createCase(listSurveyPCA);
        calculatePoint(listSurveyPCA);
    }
    
    public static void onBeforeUpdate(List<SurveyPCA__c> listSurveyPCA)
    {
        calculatePoint(listSurveyPCA);
    }
    
    public static void calculatePoint(List<SurveyPCA__c> listSurveyPCA)
    {
        Set<String> setOrderId = new Set<String>();
        for(SurveyPCA__c survey : listSurveyPCA)
        {
            if(survey.Question_0__c == 'Yes' || survey.Question_0__c == 'Có')
            {
                setOrderId.add(survey.Order__c);
            }           
        }
        
        Map<String, Schema.SObjectField> orderFieldMap = Order.sObjectType.getDescribe().fields.getMap();
        List<string> orderSelectFields = new List<String>(orderFieldMap.keySet());                
        String orderSoql = 'SELECT ' + String.join(orderSelectFields, ',');
        orderSoql += ' FROM Order';
        orderSoql += ' WHERE Id IN : setOrderId'; 
        List<Order> listOrders = Database.query(orderSoql); 
        
        Map<String, Schema.SObjectField> surveyFieldMap = SurveyPCA__c.sObjectType.getDescribe().fields.getMap();
        List<string> surveyFieldMapSelectFields = new List<String>(surveyFieldMap.keySet());                
        String surveyFieldMapSoql = 'SELECT ' + String.join(surveyFieldMapSelectFields, ',');
        surveyFieldMapSoql += ' FROM SurveyPCA__c';
        surveyFieldMapSoql += ' WHERE Order__c IN : setOrderId and (Question_0__c = \'Yes\' OR Question_0__c = \'Có\') ';  
        List<SurveyPCA__c> listSurvey = Database.query(surveyFieldMapSoql);
        Map<String,List<SurveyPCA__c>> mapSurvey = new Map<String,List<SurveyPCA__c>>();
        for(SurveyPCA__c survey : listSurvey)
        {
            if(!mapSurvey.containsKey(survey.Order__c))
            {
                mapSurvey.put(survey.Order__c,new List<SurveyPCA__c>());
            }
            mapSurvey.get(survey.Order__c).add(survey);
        }
        
        for(Order o : listOrders)
        {
            List<SurveyPCA__c> listS = mapSurvey.get(o.Id);
            Decimal CSI = 0;
            Decimal PSI = 0;
            Decimal NPS = 0;
            Decimal TSI = 0;
            
            Decimal allCSISelection = 0;
            Decimal allPSISelection = 0;
            Decimal allNPSSelection = 0;
            Decimal positiveCSISelection = 0;   
            Decimal positivePSISelection = 0;     
            Decimal positiveNPSSelection = 0;
            Decimal negativeNPSSelection = 0;
               
            for(SurveyPCA__c survey : listSurveyPCA)
            {
                allCSISelection += 1;
                if(Decimal.valueOf(survey.Question_1__c)  >= 7)
                {
                    positiveCSISelection += 1;                    
                }
                
                allPSISelection  = 10 * 10;
                
                positivePSISelection += Decimal.valueOf(survey.Question_3__c);
                positivePSISelection += Decimal.valueOf(survey.Question_4__c);
                positivePSISelection += Decimal.valueOf(survey.Question_5__c);               	
                if(survey.Question_6__c == 'No' || survey.Question_6__c == 'Không')
                {
                    positivePSISelection += 1;
                }
                else
                {
                    positivePSISelection += 10;
                }
                if(survey.Question_7__c == 'No' || survey.Question_7__c == 'Không')
                {
                   positivePSISelection += 1;
                }
                else
                {
                    positivePSISelection += 10;
                }
                if(survey.Question_8__c == 'No' || survey.Question_8__c == 'Không')
                {
                    positivePSISelection += 1;
                }
                else
                {
                    positivePSISelection += 10;
                }
                if(survey.Question_9__c == 'No' || survey.Question_9__c == 'Không')
                {
                    positivePSISelection += 1;
                }
                else
                {
                    positivePSISelection += 10;
                }
                positivePSISelection += Decimal.valueOf(survey.Question_11__c);
                positivePSISelection += Decimal.valueOf(survey.Question_12__c);  
                if(survey.Question_13__c == 'No' || survey.Question_13__c == 'Không')
                {
                    positivePSISelection += 1;
                }
                else
                {
                    positivePSISelection += 10;
                }
                
                allNPSSelection++;
                
                if(Decimal.valueOf(survey.Question_2__c)  >= 9)
                {
                    positiveNPSSelection += 1;
                }
                else if(Decimal.valueOf(survey.Question_2__c)  <= 6)
                {
                   	negativeNPSSelection += 1;
                }
			                
            }     
            
            /*CSI = positiveCSISelection / allCSISelection * 100;
            PSI = positivePSISelection / allPSISelection * 100;
            NPS = (positiveNPSSelection / listSurveyPCA.size() * 100) - (negativeNPSSelection  / listSurveyPCA.size() * 100); */
            
            o.CSI__c = allCSISelection;
            o.PSI__c = allPSISelection;
            o.NPS__c = allNPSSelection;
            
            o.CSI_Positive__c = positiveCSISelection;
            o.PSI_Positive__c = positivePSISelection;
            o.NPS_Positive__c = positiveNPSSelection;
            o.NPS_Nagative__c = negativeNPSSelection;
            
            o.Is_Surveyed__c = true;
            
        }
        
        if(!listOrders.isEmpty())
        {
            update listOrders;
        }
    }
    
    public static void createCase(List<SurveyPCA__c> listSurveyPCA)
    {
        List<Case> listCase = new List<Case>();
        for(SurveyPCA__c survey : listSurveyPCA)
        {
            String CASERECORDTYPE = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                .get('Case')
                .getRecordTypeId();
            
            Boolean isAlert = false;
            Case c = new Case();
            c.RecordTypeId = CASERECORDTYPE;
            c.Order__c = survey.Order__c;
            //c.OwnerId = survey.Order_Owner_Id__c;
            c.OwnerId = '0055g0000043OvS'; 
            c.Subject = 'Subject: '+survey.Order_Record_Type_Name__c + 'Survey Alert - ' + survey.Account_Name__c + ' - ' + survey.Order_Number__c;
            c.Description = 'Subject: '+survey.Order_Record_Type_Name__c + 'Survey Alert - ' + survey.Account_Name__c + ' - ' + survey.Order_Number__c 
                + '\n Description:';
            c.Origin = 'Survey';
            c.Status = 'Complaint Received';
            c.Group__c = 'PCA';
            
            if(Integer.valueOf(survey.Question_1__c)  < apiSetting.Question_1__c )
            {
                isAlert = true;
                c.Description += '\n What was your overall impression of the Dealership who sold your PCA? - '+ survey.Question_1__c;
            }
            if(Integer.valueOf(survey.Question_2__c) < apiSetting.Question_2__c )
            {
                isAlert = true;
                c.Description += '\n Based on your purchase experience, how likely would you be to recommend Revzone to friends or colleagues? - '+ survey.Question_2__c;
            }

            
            if(isAlert)
            {
                listCase.add(c);                
            }
        }
        if(!listCase.isEmpty())
        {
            insert listCase;
        }  
    }
}