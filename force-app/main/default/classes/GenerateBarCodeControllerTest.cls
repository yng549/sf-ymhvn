@isTest
public class GenerateBarCodeControllerTest {
	static testMethod void testMethod1() {    
        Test.startTest();
        GenerateBarCodeController.cheatTemp();
        PDFOrderPartClaimTag.cheatTemp();
        Test.stopTest();
    }
}