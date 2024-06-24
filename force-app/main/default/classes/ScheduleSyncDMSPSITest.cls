@istest
public class ScheduleSyncDMSPSITest {
     @isTest(seeAllData=true)
	 static void test() {
      Test.startTest(); 
      system.schedule('Auto Sync PSI DMS 1', '0 30 6 * * ?', new ScheduleSyncDMSPSI());
      Test.stopTest();
    }
}