public class PermissionHelper {
    public static Boolean checkPermission(PermissionType type, Schema.DescribeSObjectResult sObjectDescribeResult, String[] fieldsToCheck){
        Boolean hasPermission = false;
        if(type == PermissionType.CAN_DELETE){
            return sObjectDescribeResult.isDeletable();
        }        

        Map<String,Schema.SObjectField> fieldMapping = sObjectDescribeResult.fields.getMap();       
        String namespacePrefix = Utils.getNamespacePrefix();              
        for (String fieldToCheck : fieldsToCheck) {  
            if(fieldToCheck.contains('__c')){
                fieldToCheck = (String.isNotBlank(namespacePrefix) ? namespacePrefix + '__' : '') + fieldToCheck.toLowerCase(); 
            } else {
                fieldToCheck = fieldToCheck.toLowerCase();
            }                        
            if(type == PermissionType.CAN_CREATE){
                // Check if the user has create access on the field
                hasPermission = fieldMapping.containsKey(fieldToCheck) && fieldMapping.get(fieldToCheck).getDescribe().isCreateable();
                break;
            }
            if(type == PermissionType.CAN_UPDATE){
                // Check if the user has update access on the field
                hasPermission = fieldMapping.containsKey(fieldToCheck) && fieldMapping.get(fieldToCheck).getDescribe().isUpdateable();
                break;                
            }            
        } 
        return hasPermission;
    }

    public enum PermissionType {
        CAN_CREATE,
        CAN_UPDATE,
        CAN_DELETE
    }
}