public class TriggerSurveyServiceHandler {
    static Survey_Service_Alert__mdt apiSetting { 
        get {
            if (apiSetting == null) {                
                Survey_Service_Alert__mdt[] settings = [
                    SELECT 
                    MasterLabel, DeveloperName, Question_1__c,Question_2__c
                    FROM Survey_Service_Alert__mdt
                    WHERE DeveloperName = 'Default'
                ];              
                if(!settings.isEmpty()){
                    //system.debug(settings[0]);
                    apiSetting = settings[0];
                } else {
                    if(!Test.isRunningTest()){
                        //throw new SmsClass.SmsBrandNameException('Please setup a default API setting');
                    } else {
                        Survey_Service_Alert__mdt setting = new Survey_Service_Alert__mdt();
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
    
    public static void onBeforeInsert(List<SurveyService__c> listSurveyService)
    {
        createCase(listSurveyService);
        calculatePoint(listSurveyService);
    }
    
    public static void onBeforeUpdate(List<SurveyService__c> listSurveyService)
    {
        calculatePoint(listSurveyService);
    }
    
    public static void calculatePoint(List<SurveyService__c> listSurveyService)
    {
        Set<String> setOrderId = new Set<String>();
        for(SurveyService__c survey : listSurveyService)
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
        
        Map<String, Schema.SObjectField> surveyFieldMap = SurveyService__c.sObjectType.getDescribe().fields.getMap();
        List<string> surveyFieldMapSelectFields = new List<String>(surveyFieldMap.keySet());                
        String surveyFieldMapSoql = 'SELECT ' + String.join(surveyFieldMapSelectFields, ',');
        surveyFieldMapSoql += ' FROM SurveyService__c';
        surveyFieldMapSoql += ' WHERE Order__c IN : setOrderId and (Question_0__c = \'Yes\' OR Question_0__c = \'Có\') ';   
        List<SurveyService__c> listSurvey = Database.query(surveyFieldMapSoql);
        Map<String,List<SurveyService__c>> mapSurvey = new Map<String,List<SurveyService__c>>();
        for(SurveyService__c survey : listSurvey)
        {
            if(!mapSurvey.containsKey(survey.Order__c))
            {
                mapSurvey.put(survey.Order__c,new List<SurveyService__c>());
            }
            mapSurvey.get(survey.Order__c).add(survey);
        }
        
        for(Order o : listOrders)
        {
            List<SurveyService__c> listS = mapSurvey.get(o.Id);
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
            
            Decimal countPSISelection = 15;
               
            for(SurveyService__c survey : listSurveyService)
            {
                allCSISelection += 1;
                if(Decimal.valueOf(survey.Question_1__c)  >= 7)
                {
                    positiveCSISelection += 1;                    
                }
                
                
                if(survey.Question_3_1__c != null)
                {
                    countPSISelection++;
                    positivePSISelection += Decimal.valueOf(survey.Question_3_1__c);
                }
                if(survey.Question_3_2__c != null)
                {
                    countPSISelection++;
                    positivePSISelection += Decimal.valueOf(survey.Question_3_2__c);
                }
                               
                positivePSISelection += Decimal.valueOf(survey.Question_5__c);               	
                positivePSISelection += Decimal.valueOf(survey.Question_6__c);
                positivePSISelection += Decimal.valueOf(survey.Question_7__c);
                positivePSISelection += Decimal.valueOf(survey.Question_8__c);
                if(survey.Question_9__c == 'No' || survey.Question_9__c == 'Không')
                {
                    positivePSISelection += 1;
                }
                else
                {
                    positivePSISelection += 10;
                }
                if(survey.Question_10__c == 'No' || survey.Question_10__c == 'Không')
                {
                    positivePSISelection += 1;
                }
                else
                {
                    positivePSISelection += 10;
                }
                if(survey.Question_11__c == 'No' || survey.Question_11__c == 'Không')
                {
                    positivePSISelection += 1;
                }
                else
                {
                    positivePSISelection += 10;
                }
                if(survey.Question_13__c == 'No' || survey.Question_13__c == 'Không')
                {
                    positivePSISelection += 1;
                }
                else
                {
                    positivePSISelection += 10;
                }
                if(survey.Question_14__c == 'No' || survey.Question_14__c == 'Không')
                {
                    positivePSISelection += 1;
                }
                else
                {
                    positivePSISelection += 10;
                }
                if(survey.Question_15__c == 'No' || survey.Question_15__c == 'Không')
                {
                    positivePSISelection += 1;
                }
                else
                {
                    positivePSISelection += 10;
                }
                positivePSISelection += Decimal.valueOf(survey.Question_16__c);
                positivePSISelection += Decimal.valueOf(survey.Question_17__c);
                positivePSISelection += Decimal.valueOf(survey.Question_18__c);
                if(survey.Question_19__c == 'No' || survey.Question_19__c == 'Không')
                {
                    positivePSISelection += 1;
                }
                else
                {
                    positivePSISelection += 10;
                }
                if(survey.Question_20__c == 'No' || survey.Question_20__c == 'Không')
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

			allPSISelection  = 10 * countPSISelection;
            
            /*CSI = positiveCSISelection / allCSISelection * 100;
            PSI = positivePSISelection / allPSISelection * 100;
            NPS = (positiveNPSSelection / listSurveyService.size() * 100) - (negativeNPSSelection  / listSurveyService.size() * 100); */
            
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
    
    public static void createCase(List<SurveyService__c> listSurveyService)
    {
        List<Case> listCase = new List<Case>();
        for(SurveyService__c survey : listSurveyService)
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
            c.Group__c = 'Service';
            
            if(Integer.valueOf(survey.Question_1__c)  < apiSetting.Question_1__c )
            {
                isAlert = true;
                c.Description += '\n What was your overall impression of the Dealership where you bought new bike? - '+ survey.Question_1__c;
            }
            if(Integer.valueOf(survey.Question_2__c) < apiSetting.Question_2__c )
            {
                isAlert = true;
                c.Description += '\n Based on your purchase experience, how likely would you be to recommend Revzone to friends or colleagues? - '+ survey.Question_2__c;
            }
            /*if(survey.Question_21_1__c == 'No')
            {
                isAlert = true;
                c.Description += '\n Do you feel that the dealer is doing everything they can to resolve the problem? - '+ survey.Question_21_1__c;
            }*/
            
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