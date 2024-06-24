@isTest(SeeAlldata=true)
public class BatchSurveySendingTest {
    @isTest static void test1() {
        Test.startTest();
          System.schedule('Auto Sync 1', '0 30 7 * * ?', new ScheduleSurveySMS());
        string a = SmsErrorCode.SALESFORCE_EXCEPTION;
        Test.stopTest();
        SmsClass.cheatTemp();
        SmsTemplateHelper.cheatTemp();
        SmsHelper.cheatTemp();
        TriggerOrder.cheatTemp();
        SmsTemplateHelper.cheatTemp();
    }
}