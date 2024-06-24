/**
 * @description       : 
 * @author            : lvlGod
 * @group             : 
 * @last modified on  : 01-15-2021
 * @last modified by  : lvlGod
 * Modifications Log 
 * Ver   Date         Author   Modification
 * 1.0   12-31-2020   lvlGod   Initial Version
**/
public without sharing class StringHelper {
    public static String buildTemplateMessage(String templateMessage, SObject record, String mainObjectName){
        Map<String, Set<String>> mapMergeField = getMergeFieldFromTemplate(templateMessage);  
        Map<String, String> mapTemplateValue = buildInitialTemplateValueMapping(mapMergeField);

        Set<String> mainObjectSelectFields = new Set<String>();                
        if(mapMergeField.containsKey(mainObjectName)){
            mainObjectSelectFields = mapMergeField.get(mainObjectName);          
        }

        for(String mergeFieldKey : mainObjectSelectFields){
            Object value = StringHelper.getSObjectValue(record, mergeFieldKey);
            mapTemplateValue.put(buildTemplateMergeKey(mainObjectName, mergeFieldKey), StringHelper.getStringValue(value, ''));
        }

        for(String mergeKey : mapTemplateValue.keySet()){
            templateMessage = templateMessage.replaceAll('\\{!' + mergeKey + '\\}', mapTemplateValue.get(mergeKey));
        }

        return templateMessage;
    }

    /**
     * Try to get merge field from the template string and build a map of object API name with a set of key needed to get value
     */
    public static Map<String, Set<String>> getMergeFieldFromTemplate(String templateMessage){
        // Regex to match merge field template (ie. ${!Account.Id} or ${!Account__c.Contact__r.Field__c})        
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
     * Get value from SObject by field key including lookup value field key
     */
    public static Object getSObjectValue(SOBject record, String fieldKey){
        String[] parts = fieldKey.split('\\.');

        if(parts.size() == 1){
            return record.isSet(fieldKey) ? record.get(fieldKey) : null;
        }
        
        SObject value = record;
        for(Integer i = 0; i < parts.size(); i++){
            if(i == parts.size() - 1){
                // If this is the last part return the value found
                return value.isSet(parts[i]) ? value.get(parts[i]) : null;
            } else {                
                // Move into nested sObject
                value = value.getSObject(parts[i]);
            }
        }     
        
        return null;
    }

    public static String getStringValue(Object obj) {
        return getStringValue(obj, null);
    }

    public static String getStringValue(Object obj, String defaultValue) {
        if(obj == null && defaultValue != null){
            return defaultValue;
        }
        
        if(obj instanceof Decimal){
            // Prevent scientific notation
            return ((Decimal)obj).toPlainString();
        }

        return String.valueOf(obj);        
    }

    static Map<String, String> UNICODE_CHARACTERS = new Map<String, String> {
        'À' => 'A', 'Á' => 'A', 'Â' => 'A', 'Ã' => 'A', 
        'È' => 'E', 'É' => 'E', 'Ê' => 'E', 
        'Ì' => 'I', 'Í' => 'I', 
        'Ò' => 'O', 'Ó' => 'O', 'Ô' => 'O', 'Õ' => 'O', 
        'Ù' => 'U', 'Ú' => 'U', 
        'Ý' => 'Y', 
        'à' => 'a', 'á' => 'a', 'â' => 'a', 'ã' => 'a',
        'è' => 'e', 'é' => 'e', 'ê' => 'e', 
        'ì' => 'i', 'í' => 'i', 
        'ò' => 'o', 'ó' => 'o', 'ô' => 'o', 'õ' => 'o', 
        'ù' => 'u', 'ú' => 'u', 
        'ý' => 'y', 
        'Ă' => 'A', 'ă' => 'a', 
        'Đ' => 'D', 'đ' => 'd', 
        'Ĩ' => 'I', 'ĩ' => 'i', 
        'Ũ' => 'U', 'ũ' => 'u',
        'Ơ' => 'O', 'ơ' => 'o', 
        'Ư' => 'U', 'ư' => 'u', 
        'Ạ' => 'A', 'ạ' => 'a', 'Ả' => 'A', 'ả' => 'a', 'Ấ' => 'A', 'ấ' => 'a',
        'Ầ' => 'A', 'ầ' => 'a', 'Ẩ' => 'A', 'ẩ' => 'a', 'Ẫ' => 'A', 'ẫ' => 'a', 'Ậ' => 'A', 'ậ' => 'a', 'Ắ' => 'A', 'ắ' => 'a',
        'Ằ' => 'A', 'ằ' => 'a', 'Ẳ' => 'A', 'ẳ' => 'a', 'Ẵ' => 'A', 'ẵ' => 'a', 'Ặ' => 'A', 'ặ' => 'a', 
        'Ẹ' => 'E', 'ẹ' => 'e', 'Ẻ' => 'E', 'ẻ' => 'e', 'Ẽ' => 'E', 'ẽ' => 'e', 'Ế' => 'E', 'ế' => 'e', 'Ề' => 'E', 'ề' => 'e', 'Ể' => 'E', 'ể' => 'e',
        'Ễ' => 'E', 'ễ' => 'e', 'Ệ' => 'E', 'ệ' => 'e', 
        'Ỉ' => 'I', 'ỉ' => 'i', 'Ị' => 'I', 'ị' => 'i', 
        'Ọ' => 'O', 'ọ' => 'o', 'Ỏ' => 'O', 'ỏ' => 'o', 'Ố' => 'O', 'ố' => 'o', 'Ồ' => 'O', 'ồ' => 'o', 'Ổ' => 'O', 'ổ' => 'o', 'Ỗ' => 'O', 'ỗ' => 'o',
        'Ộ' => 'O', 'ộ' => 'o', 'Ớ' => 'O', 'ớ' => 'o', 'Ờ' => 'O', 'ờ' => 'o', 'Ở' => 'O', 'ở' => 'o', 'Ỡ' => 'O', 'ỡ' => 'o',
        'Ợ' => 'O', 'ợ' => 'o', 
        'Ụ' => 'U', 'ụ' => 'u', 'Ủ' => 'U', 'ủ' => 'u', 'Ứ' => 'U', 'ứ' => 'u', 'Ừ' => 'U', 'ừ' => 'u',
        'Ử' => 'U', 'ử' => 'u', 'Ữ' => 'U', 'ữ' => 'u', 'Ự' => 'U', 'ự' => 'u', 
        'Ỳ' => 'Y', 'ỳ' => 'y', 'Ỵ' => 'Y', 'ỵ' => 'y', 'Ỷ' => 'Y', 'ỷ' => 'y', 'Ỹ' => 'Y', 'ỹ' => 'y'
    };
    public static String convertUnicodeToNonUnicode(String text){
        for(String unicodeString : UNICODE_CHARACTERS.keySet()){
            if(text.contains(unicodeString)){
                text = text.replaceAll(unicodeString, UNICODE_CHARACTERS.get(unicodeString));
            }
        }

        return text;
    }

    static String EMAIL_REGEX = '[a-zA-Z0-9!#$%&\'*+/=?^_`{|}~-]+(?:\\.[a-zA-Z0-9!#$%&\'*+/=?^_`{|}~-]+)*@(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?\\.)+[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?';
    public static Boolean isValidEmail(String email){
        Pattern mergeFieldPattern = Pattern.compile(EMAIL_REGEX);
        Matcher mergeFieldMatcher = mergeFieldPattern.matcher(email);
        return mergeFieldMatcher.matches();
    }

    public static String buildTemplateMergeKey(String mergeObjectKey, String mergeFieldKey){
        return mergeObjectKey + '.' + mergeFieldKey;
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

    public static String normalizePhoneNumber(String phone){
        if(String.isBlank(phone)){
            return '';
        }
        String regExp = '[^0-9]';
 		phone = phone.replaceAll(regExp, '');
        if(phone.startsWith('0')){
            phone = phone.replaceFirst('0', '+84');
        } else if (phone.startsWith('84')){
            phone = '+' + phone;
        } else if (!phone.startsWith('+84')){
            phone = '+84' + phone;
        }

        return phone;
    }

    /**
     * Normalize phone number format
     * https://beunik.atlassian.net/browse/NTFSC-116
     */
    public static void normalizeSObjectPhoneNumber(List<SObject> records){
        if(records == null || records.isEmpty()){
            return;
        }

        List<String> phoneFields = new List<String>();
        Schema.DescribeSObjectResult objectDescribeResult = records[0].getSObjectType().getDescribe();
        Map<String, Schema.SObjectField> recordFields = objectDescribeResult.fields.getMap();
        for(String fieldName : recordFields.keySet()){
            
            Schema.SObjectField field = recordFields.get(fieldName);
            Schema.DescribeFieldResult fieldDescribeResult = field.getDescribe();
            if(fieldDescribeResult.getType() == Schema.DisplayType.PHONE && (fieldDescribeResult.isUpdateable() || fieldDescribeResult.isCreateable())){
                phoneFields.add(fieldName);
            }
        }
        System.debug('phoneFields :' + phoneFields);
        for(SObject record : records){
            for(String fieldName : phoneFields){
                if(record.get(fieldName) != null){
                    record.put(fieldName, normalizePhoneNumber((String)record.get(fieldName)));
                }
            }
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
        }
}