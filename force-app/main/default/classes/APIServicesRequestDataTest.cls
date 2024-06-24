@istest
public class APIServicesRequestDataTest {
	@isTest(seeAllData=true)
    static void testSync1() {
        string json = '{\"RequestNo\":\"RY01A\",\"ApplicationPointCode\":\"RY01A\",\"AuthorizationNo\":\"\",\"ApplicationDealerCode\":\"RY01\",\"ApplicationDate\":\"2023-02-07\",\"FrameNo\":\"JYARN7040MA000389\",\"SalesDate\":\"2022-04-04\",\"FailureDate\":\"2023-01-30\",\"Mileage\":\"1545\",\"SymptomCode\":\"B5\",\"SectionCode\":\"PS02\",\"ConditionCode\":\"9A\",\"ProblemDescription\":\"Xerấtnóng,khivặnga-nhiệtđộluôntăng.Quạtlàmmátkhôngquay.\",\"CauseDescription\":\"Quạtlàmmátkhôngquay.Khôngcódấutháolắp.\",\"RepairDescription\":\"Thayquạtlàmmát.\",\"DealerComment\":\"Quạttảnnhiệtkhôngquay,khiđộngcơnóng.\",\"PrimaryFailedPartNo\":\"B7N124050000\",\"CampaignNumber\":\"\",\"ClaimType\":\"REGULAR\",\"ClaimApplicationNo\":\"2302A0005\",\"RepairCompletionDate\":\"2022-07-31\",\"JobDetails\":[{\"JobCode\":\"null\"}],\"PartsDetails\":[{\"ExchangePartNo\":\"B7N124050000\",\"ExchangePartQuantity\":\"1\"}]}';
    	RestRequest request = new RestRequest();
        request.requestUri = '/APIServicesRequestData/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(json);

        RestContext.request = request;
        RestContext.response = new RestResponse();
        APIServicesRequestData.Run();
    }
}