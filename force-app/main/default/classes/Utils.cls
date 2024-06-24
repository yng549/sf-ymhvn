/**
 * @description       : 
 * @author            : Steven Duong
 * @group             : 
 * @last modified on  : 10-16-2021
 * @last modified by  : Steven Duong
**/
public with sharing class Utils {
    private static String cachedNamespacePrefixValue = null;
    public static Boolean inOrderTrigger =false;
    public static String orderIdWithPromtion = null;

    public static String getNamespacePrefix() {
        if(Utils.cachedNamespacePrefixValue != null){
            return Utils.cachedNamespacePrefixValue;
        }

        String namespacePrefix = '';
        String[] classNameParts = String.valueOf(Utils.class).split('\\.', 2);
        if(classNameParts.size() > 1) {
            Type classType = Type.forName(classNameParts[0], classNameParts[1]);
            if(classType == Utils.class) {
                namespacePrefix = classNameParts[0];
            }
        }

        Utils.cachedNamespacePrefixValue = namespacePrefix;
        return namespacePrefix; 
    }

    public static Decimal getNumberValue(Decimal value){
        return value != null ? value : 0;
    }

    public class Omn1Exception extends Exception {}

    
}