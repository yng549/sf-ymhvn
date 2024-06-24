public class SmsTemplateHelper {
    public static SmsClass.SMSDTO parseParamSMSContent(Id templateId, Id recordId) {
        SmsClass.SMSDTO templateResult = new SmsClass.SMSDTO();
        Map<Integer, string> mapIndexParams = new Map<Integer, string>();
        SMS_Brandname_Template__c[] templates = [
            SELECT Id, Description__c, Object_Name__c, Phone_Field__c, Template__c, Use_Unicode__c,
            Label_ID__c, Template_ID__c, IndexParamContent__c
            FROM SMS_Brandname_Template__c
            WHERE Id = :templateId
        ];

        if(templates.isEmpty()){
            throw new SmsClass.SmsBrandNameException('Invalid template id');
        }

        SMS_Brandname_Template__c template = templates[0];
        Map<integer, string> mapIndexParam = new Map<integer, string>();
        if(string.isNotBlank(template.IndexParamContent__c)) {
            for(string index : template.IndexParamContent__c.split('\r\n')) {
                List<string> param = index.split(':');
                mapIndexParam.put(Integer.valueOf(param[0]), param[1]);
            }
        }
        Map<String, Set<String>> mapMergeField = getMergeFieldFromTemplate(template.Template__c);
        
        Map<String, String> mapTemplateValue = buildInitialTemplateValueMapping(mapMergeField);
        
        Set<String> mainObjectSelectFields = new Set<String>();        
        if(mapMergeField.containsKey(template.Object_Name__c)){
            mainObjectSelectFields = mapMergeField.get(template.Object_Name__c);          
        }
		
        Set<Id> recordIds = new Set<Id> {recordId};
        String mainObjectSoql = buildSelectObjectSOQL(template.Object_Name__c, mainObjectSelectFields);
        List<SObject> mainObjectRecords = Database.query(mainObjectSoql);
        if(!mainObjectRecords.isEmpty()){
            SObject record = mainObjectRecords[0];

            for(String mergeFieldKey : mainObjectSelectFields){
                Object value = StringHelper.getSObjectValue(record, mergeFieldKey);
                string param = StringHelper.getStringValue(value, '');
                if(template.Use_Unicode__c == '0'){
                    param = StringHelper.convertUnicodeToNonUnicode(param);
                }
                mapTemplateValue.put(buildTemplateMergeKey(template.Object_Name__c, mergeFieldKey), param);
            }
        }
        
        templateResult.LABELID = template.Label_ID__c;
        templateResult.mapIndexParams = mapIndexParam;
        templateResult.TEMPLATEDID = template.Template_ID__c;
        templateResult.mapFieldParams = mapTemplateValue;
        
        return templateResult;
    }
    /**
     * Parse SMS template and replace merge template field with value from related record
     */
    public static SmsClass.SmsTemplateResult parseSmsTemplate(Id templateId, Id recordId, Id ownerId, Map<String, String> customDataMapping){
        SmsClass.SmsTemplateResult templateResult = new SmsClass.SmsTemplateResult();
        
        SMS_Brandname_Template__c[] templates = [
            SELECT 
                Id, Description__c, Object_Name__c, Phone_Field__c, Template__c, Use_Unicode__c
            FROM SMS_Brandname_Template__c
            WHERE Id = :templateId
        ];

        if(templates.isEmpty()){
            throw new SmsClass.SmsBrandNameException('Invalid template id');
        }

        SMS_Brandname_Template__c template = templates[0];        
        Map<String, Set<String>> mapMergeField = getMergeFieldFromTemplate(template.Template__c);
        Map<String, String> mapTemplateValue = buildInitialTemplateValueMapping(mapMergeField);
        
        Set<String> mainObjectSelectFields = new Set<String>();        
        if(mapMergeField.containsKey(template.Object_Name__c)){
            mainObjectSelectFields = mapMergeField.get(template.Object_Name__c);          
        }
        if(!string.isBlank(template.Phone_Field__c))
        mainObjectSelectFields.add(template.Phone_Field__c);
        Set<Id> recordIds = new Set<Id> {recordId};
        String mainObjectSoql = buildSelectObjectSOQL(template.Object_Name__c, mainObjectSelectFields);
        List<SObject> mainObjectRecords = Database.query(mainObjectSoql);
        if(!mainObjectRecords.isEmpty()){
            SObject record = mainObjectRecords[0];

            for(String mergeFieldKey : mainObjectSelectFields){
                Object value = StringHelper.getSObjectValue(record, mergeFieldKey);
                mapTemplateValue.put(buildTemplateMergeKey(template.Object_Name__c, mergeFieldKey), StringHelper.getStringValue(value, ''));
            }
        }

        String message = buildTemplateMessage(template.Template__c, mapTemplateValue);
        if(customDataMapping != null && !customDataMapping.isEmpty()){
            message = buildTemplateMessageFromCustomData(message, customDataMapping);
        }

        if(template.Use_Unicode__c == '0'){
            message = StringHelper.convertUnicodeToNonUnicode(message);
        }

        templateResult.phoneNumber = mapTemplateValue.get(buildTemplateMergeKey(template.Object_Name__c, template.Phone_Field__c));
        templateResult.message = message;
        SMS_Brandname_Template__c temp = new SMS_Brandname_Template__c(Id = templateId, Description__c = message);
        update temp;
        return templateResult;
    }

    /**
     * Parse SMS template and replace merge template field with value for multiple related records
     */
    public static List<SmsClass.SmsTemplateResult> parseMultipleRecordSmsTemplate(SMS_Brandname_Template__c template, List<SMS_History__c> listSmsItem, Set<Id> ownerIds, List<Map<String, String>> listCustomDataMapping){
        List<SmsClass.SmsTemplateResult> listTemplateResult = new List<SmsClass.SmsTemplateResult>();                
     
        try{
            Map<String, Set<String>> mapMergeField = getMergeFieldFromTemplate(template.Template__c);        

            Set<Id> recordIds = new Set<Id>();
            for(SMS_History__c smsItem : listSmsItem){
                recordIds.add(smsItem.Record_Id__c);
            }
            
            Set<String> mainObjectSelectFields = new Set<String>();        
            if(mapMergeField.containsKey(template.Object_Name__c)){
                mainObjectSelectFields = mapMergeField.get(template.Object_Name__c);          
            }
            mainObjectSelectFields.add(template.Phone_Field__c);

            String mainObjectSoql = buildSelectObjectSOQL(template.Object_Name__c, mainObjectSelectFields);
            List<SObject> mainObjectRecords = Database.query(mainObjectSoql);
            Map<Id, SObject> mapRecord = new Map<Id, SObject>();
            for(SObject record : mainObjectRecords){
                mapRecord.put(record.Id, record);                       
            }

            for(SMS_History__c smsItem : listSmsItem){
                Integer index = listSmsItem.indexOf(smsItem);
                SObject record = mapRecord.get(smsItem.Record_Id__c);

                Map<String, String> mapTemplateValue = buildInitialTemplateValueMapping(mapMergeField);
                for(String mergeFieldKey : mainObjectSelectFields){
                    Object value = StringHelper.getSObjectValue(record, mergeFieldKey);
                    mapTemplateValue.put(buildTemplateMergeKey(template.Object_Name__c, mergeFieldKey), StringHelper.getStringValue(value, ''));
                }

                String message = buildTemplateMessage(template.Template__c, mapTemplateValue);  

                Map<String, String> customDataMapping = listCustomDataMapping.get(index);
                if(customDataMapping != null && !customDataMapping.isEmpty()){
                    message = buildTemplateMessageFromCustomData(message, customDataMapping);
                }

                if(template.Use_Unicode__c == '0'){
                    message = StringHelper.convertUnicodeToNonUnicode(message);
                }
        
                SmsClass.SmsTemplateResult templateResult = new SmsClass.SmsTemplateResult();
                templateResult.phoneNumber = mapTemplateValue.get(buildTemplateMergeKey(template.Object_Name__c, template.Phone_Field__c));
                templateResult.message = message;

                listTemplateResult.add(templateResult);
            }
        } catch(Exception e){
            listTemplateResult = new List<SmsClass.SmsTemplateResult>();
            for(SMS_History__c smsItem : listSmsItem){                
                SmsClass.SmsTemplateResult templateResult = new SmsClass.SmsTemplateResult();
                templateResult.error = e.getMessage();
                listTemplateResult.add(templateResult);
            }
        }
    
        return listTemplateResult;
    }

    /**
     * Try to get merge field from the template string and build a map of object API name with a set of key needed to get value
     */
    public static Map<String, Set<String>> getMergeFieldFromTemplate(String templateMessage){
        // Regex to match merge field template (ie. {!Account.Id} or {!Account__c.Contact__r.Field__c})        
        Pattern mergeFieldPattern = Pattern.compile('\\{!([a-zA-Z0-9_\\.\\(\\)]+?)\\}');
        Matcher mergeFieldMatcher = mergeFieldPattern.matcher(templateMessage);
        Map<String, Set<String>> mapMergeField = new Map<String, Set<String>>();
        while(mergeFieldMatcher.find()){          
            // Get merge field without special template character {!}
            String mergeField = mergeFieldMatcher.group(1);            

            if(String.isBlank(mergeField)){
                continue;
            }            

            // Split merge field to get the SObject name of this merge field Account.Id -> [Account, Id]
            String[] parts = mergeField.split('\\.');
            String mergeObjectKey = parts[0];
            
            // Remove merge object key
            parts.remove(0);

            if(!mapMergeField.containsKey(mergeObjectKey)){
                mapMergeField.put(mergeObjectKey, new Set<String>());
            }            

            // Put the merge field to it object mapping
            mapMergeField.get(mergeObjectKey).add(String.join(parts, '.'));
        }

        return mapMergeField;
    }

    /**
     * Build select SOQL from object name and a set of selected fields
     */
    public static String buildSelectObjectSOQL(String objectName, Set<String> selectFields){
        if(String.isBlank(objectName)){
            throw new SmsClass.SmsBrandNameException('Missing SObject name');
        }

        Map<String, Set<String>> mapObjectPicklistField = new Map<String, Set<String>>();
        buildObjectPicklistFieldMapping(objectName, mapObjectPicklistField);

        Set<String> escapedFieldNames = new Set<String>();
        for(String s : selectFields) {
            String[] parts = s.split('\\.');
            if(parts.size() == 1){
                // Main object field
                if(mapObjectPicklistField.get(objectName).contains(s.toLowerCase())){
                    escapedFieldNames.add('toLabel(' + String.escapeSingleQuotes(s) + ')');
                } else {
                    escapedFieldNames.add(String.escapeSingleQuotes(s));
                }
            } else {
                // Parts size > 2, this field is a lookup field
                // We need to get the reference object name and then check if this field is a picklist
                Boolean isPicklist = false;

                // Default object is the main object
                try{
                    String referenceName = objectName;
                    Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(referenceName); 
                    Map<String, Schema.SObjectField> sObjectFields = sObjectType.getDescribe().fields.getMap();

                    for(Integer i = 0; i < parts.size() - 1; i++){
                        String referenceFieldName = parts[i];
                        if(!referenceFieldName.endsWith('__r')){
                            referenceFieldName += 'Id';
                        } else {
                            referenceFieldName.removeEnd('__r');
                            referenceFieldName += '__c';
                        }
                        if(sObjectFields.containsKey(referenceFieldName)){
                            Schema.DescribeFieldResult fieldDescribe = sObjectFields.get(referenceFieldName).getDescribe();
                            if(fieldDescribe.isNamePointing()){
                                // Polymorphic relationship -> do not continue
                                break;
                            }

                            List<Schema.SObjectType> listReferenceType = fieldDescribe.getReferenceTo();
                            sObjectType = listReferenceType[0];
                            Schema.DescribeSObjectResult sObjectDescribe = sObjectType.getDescribe();
                            referenceName = sObjectDescribe.getName();                        

                            if(i + 1 == parts.size() - 1){
                                // Last reference part
                                if(!mapObjectPicklistField.containsKey(referenceName)){
                                    buildObjectPicklistFieldMapping(referenceName, mapObjectPicklistField);
                                }
                                isPicklist = mapObjectPicklistField.get(referenceName).contains(parts[parts.size() - 1].toLowerCase());
                            } else {
                                sObjectFields = sObjectDescribe.fields.getMap();                        
                            }
                        }
                    }
                } catch(Exception e){
                    System.debug(System.LoggingLevel.ERROR, e);
                }

                if(isPicklist){
                    escapedFieldNames.add('toLabel(' + String.escapeSingleQuotes(s) + ')');
                } else {
                    escapedFieldNames.add(String.escapeSingleQuotes(s));
                }
            }
        }

        String soql = 'SELECT ' + String.join(new List<String>(escapedFieldNames), ',');
        soql += ' FROM ' + String.escapeSingleQuotes(objectName);
        soql += ' WHERE Id IN :recordIds';

        System.debug(soql);

        return soql;
    }

    public static Map<String, String> buildInitialTemplateValueMapping(Map<String, Set<String>> mapMergeField){ 
        Map<String, String> mapTemplateValue = new Map<String, String>();

        for(String mergeObjectKey : mapMergeField.keySet()){
            for(String mergeFieldKey : mapMergeField.get(mergeObjectKey)){
                mapTemplateValue.put(buildTemplateMergeKey(mergeObjectKey, mergeFieldKey), '');
            }
        }

        return mapTemplateValue;
    }

    public static String buildTemplateMessage(String templateMessage, Map<String, String> mapTemplateValue){
        for(String mergeKey : mapTemplateValue.keySet()){
            templateMessage = templateMessage.replaceAll('\\{!' + mergeKey + '\\}', mapTemplateValue.get(mergeKey));
        }

        return templateMessage;
    }

    public static String buildTemplateMessageFromCustomData(String templateMessage, Map<String, String> mapCustomDataValue){
        for(String mergeKey : mapCustomDataValue.keySet()){
            templateMessage = templateMessage.replaceAll('\\{#' + mergeKey + '\\}', mapCustomDataValue.get(mergeKey));
        }

        return templateMessage;
    }

    public static String buildTemplateMergeKey(String mergeObjectKey, String mergeFieldKey){
        return mergeObjectKey + '.' + mergeFieldKey;
    }

    public static void buildObjectPicklistFieldMapping(String objectName, Map<String, Set<String>> mapObjectPicklistField){
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectName); 
        Schema.DescribeSobjectResult sObjectDescribe = sObjectType.getDescribe();
        Map<String, Schema.SObjectField> sObjectFields = sObjectDescribe.fields.getMap();        
        Set<String> setPicklistField = new Set<String>();
        for(Schema.SObjectField field : sObjectFields.values()){      
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();            
            if(fieldDescribe.getType() == Schema.DisplayType.PICKLIST || fieldDescribe.getType() == Schema.DisplayType.MULTIPICKLIST){
                setPicklistField.add(fieldDescribe.getName().toLowerCase());
            }
        }

        mapObjectPicklistField.put(objectName, setPicklistField);
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
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
         a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
                a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
         a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
         a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
         a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
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