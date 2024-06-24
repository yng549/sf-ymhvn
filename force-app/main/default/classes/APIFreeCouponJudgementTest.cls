@isTest(SeeAllData = True)
public class APIFreeCouponJudgementTest {
// IV.3 partmenifest Data
    @isTest
    static void testSyncSuccess() {
        string data = '{\"CouponApplicationNo\":\"2109A0001\",\"RequestNo\":\"2109A0001\",\"ApplicationPointCode\":\"RY01\",\"AuthorizationNo\":\"1\",\"ApplicationDealerCode\":\"RY01A\",\"ApplicationDate\":\"2022-06-01\",\"FrameNo\":\"MH3RH07Z0MK001071\",\"SalesDate\":\"2021-06-01\",\"FailureDate\":\"2022-06-01\",\"Mileage\":\"30000\",\"SymptomCode\":\"K0\",\"ConditionCode\":\"A2\",\"ProblemDescription\":\"Hócgióhúkêuto\",\"CauseDescription\":\"Nướcvào\",\"RepairDescription\":\"Thaynhớt\",\"DealerComment\":\"XeOrderBenThai\",\"PrimaryFailedPartNo\":\"BBR-SH392-M3-GR\",\"CampaignNumber\":\"1000\",\"ClaimType\":\"Test\",\"ClaimApplicationNo\":\"11111\",\"RepairCompletionDate\":\"2022-06-01\",\"JobDetails\":[{\"JobCode\":\"SV-12\"},{\"JobCode\":\"CA-1\"},{\"JobCode\":\"Yoyotest\"}],\"PartsDetails\":[{\"ExchangePartNo\":\"BBR-FUELC-M3-SV\",\"ExchangePartQuantity\":\"1\"},{\"ExchangePartNo\":\"BBR-SH392-M3-GR\",\"ExchangePartQuantity\":\"1\"}]}';
        
		string jsonreq = '{\"CouponApplicationNo\":\"2109A0001\",\"ApplicationPointCode\":\"RY01\",\"ApplicationDealerCode\":\"RY01A\",\"YnspireReceiptNo\":\"2034912\",\"YnspireReceiptDate\":\"2022-05-10\",\"CouponStatusCode\":\"12131929121\",\"CouponStatusName\":\"Approved\",\"PaymentLaborAmount\":\"18000000\",\"FrameNo\":\"MH3RH07Z0MK001071\",\"CouponLevel\":\"6\",\"CouponServiceDate\":\"2022-03-30\",\"Mileage\":\"1000\",\"AccountingMonth\":\"4\",\"CouponAdujudicationMessage\":\"FirstBike\"}';
        RestResponse res1 = new RestResponse();
        
        RestRequest request1 = new RestRequest();
        request1.requestUri = '/APIServicesRequestCouponData/';
        request1.httpMethod = 'POST';
        request1.requestBody = Blob.valueOf(data);
        request1.addHeader('Content-Type', 'application/json');
        RestContext.request = request1;
        RestContext.response = res1;
        APIServicesRequestCouponData.run();
        
        
        RestResponse res = new RestResponse();
        Test.startTest();
        RestRequest request = new RestRequest();
        request.requestUri = '/APIFreeCouponJudgement/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(jsonreq);
        request.addHeader('Content-Type', 'application/json');
        RestContext.request = request;
        RestContext.response = res;
        APIFreeCouponJudgement.run();
        Test.stopTest();
    }
}