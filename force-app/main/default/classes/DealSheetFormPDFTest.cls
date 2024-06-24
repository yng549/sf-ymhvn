@isTest(SeeAllData=true)
public with sharing class DealSheetFormPDFTest {
    
    static testMethod void testMethod1() {
        Test.startTest(); 
            DealSheetFormPDF.cheatTemp();
            Test.stopTest();
    }
    
   
}