@isTest(SeeAllData = True)
public class SyncServiceJobPriceDMSTest {
	@isTest
    static void testSyncMCInvenJobSuccess() {
        string jsondata = '{\"msg\":\"Requestsucceed.\",\"code\":200,\"data\":[{\"ProductLineCode\":\"10\"},{\"FlatrateGroups\":{\"FlatrateGroupName\":\"YZF250/A,YZF320/A\",\"FlatrateGroupCode\":\"6548054\",\"UpdateDate\":\"20220407\",\"detail\":[{\"jobs\":{\"JobCode\":\"S598\",\"FlatRate\":0.2,\"LabourCost\":65000,\"totalCostForAT\":10000,\"FlatRateForAT\":null,\"LaborCostForDOAT\":null,\"TotalCostForDOAT\":null,\"FlatRateForDOMP\":null,\"LaborCostForDOMP\":null,\"TotalCostForDOMP\":null,\"FlatRateForDOBIGBIKE\":null,\"LaborCostForBIGBIKE\":null,\"TotalCostForBIGBIKE\":null}},{\"jobs\":{\"JobCode\":\"9640\",\"FlatRate\":3.2,\"LabourCost\":65000,\"totalCostForAT\":210000,\"FlatRateForAT\":2.6,\"LaborCostForDOAT\":65000,\"TotalCostForDOAT\":170000,\"FlatRateForDOMP\":2.6,\"LaborCostForDOMP\":65000,\"TotalCostForDOMP\":170000,\"FlatRateForDOBIGBIKE\":4.45,\"LaborCostForBIGBIKE\":230000,\"TotalCostForBIGBIKE\":1020000}},{\"ModelTypes\":{\"ModelTypeCode\":\"B5LD\"}},{\"ModelTypes\":{\"ModelTypeCode\":\"B5LN\"}},{\"ModelTypes\":{\"ModelTypeCode\":\"B5LW\"}}]}}]}';
        MockDMSHelperResponse.setTestMockResponse(200, 'OK', jsondata);
       
        Test.startTest();
        System.schedule('Auto Sync JobPrice DMS', '0 30 6 * * ?', new ScheduleServiceJobPrice());
        Test.stopTest();
    }
    @isTest
    static void testSyncMCInvenJobHN() {
       
        Test.startTest();
        System.schedule('Auto Sync JobPrice HN Test DMS', '0 30 6 * * ?', new ScheduleServiceJobPriceHN());
        Test.stopTest();
    }
}