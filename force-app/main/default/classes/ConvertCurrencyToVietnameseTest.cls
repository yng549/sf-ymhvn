@isTest
public class ConvertCurrencyToVietnameseTest {
    static testMethod void testMethod1() {    
        Test.startTest();
        Decimal so = 112345678;
        ConvertCurrencyToVietnamese.convertV(so);
        Test.stopTest();
    }
}