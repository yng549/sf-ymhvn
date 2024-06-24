@isTest
global class EinvoiceMockResponse implements HttpCalloutMock{
	global HTTPResponse respond(HTTPRequest req) {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        
        String requestEndpoint = req.getEndpoint();
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'text/xml;charset=utf-8;');
        res.setBody('<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><soap:Body><ImportAndPublishInvResponse xmlns="http://tempuri.org/"><ImportAndPublishInvResult>OK:1/001;C22TMC-696999559999999_0000001</ImportAndPublishInvResult></ImportAndPublishInvResponse></soap:Body></soap:Envelope>');
        res.setStatusCode(200);
        return res;
    }
}