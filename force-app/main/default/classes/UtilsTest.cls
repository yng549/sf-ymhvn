@isTest
public class UtilsTest {
    @IsTest
    static void test_getNamespacePrefix(){        
        Test.startTest();
        Utils.getNamespacePrefix();
        Utils.getNamespacePrefix();
        Test.stopTest();        
    }

    @IsTest
    static void test_getNumberValue(){        
        Test.startTest();
        Utils.getNumberValue(1);
        Test.stopTest();        
    }
}