@RestResource(urlMapping = '/APIServiceBooking/*')
global  without sharing class APIServiceBooking {
    // Error code definition : {error code => http status code, error message}
    private static final Map<String, errDef> err = new Map<String, errDef> {
        'SUCCESS'                   	=> new errDef(200, 'Success'),
        'PARAM_NOAPPOINTMENTCODE'       => new errDef(400, 'Appointment code required'),    
        'PARAM_NOBRAND'          		=> new errDef(400, 'Brand required'),
        'PARAM_NOMODEL'  				=> new errDef(400, 'Model invalid'),
        'PARAM_NOFULLNAME'  			=> new errDef(400, 'Name resigner required'),
        'PARAM_NOMOBILE'       			=> new errDef(400, 'ApplicationPointCode required'),
        'PARAM_NOEMAIL'       			=> new errDef(400, 'FrameNo required'),
        'PARAM_NOBOOKINGTIME'       	=> new errDef(400, 'Booking time required'),
        'PARAM_DODLNOTFOUND' 			=> new errDef(404, 'DO/DL not found'),
        'ERROR_EXCEPTION'           	=> new errDef(500, 'Exception occured')
    };    
    // http request 
    private static RestRequest req = RestContext.request;
    private static RestResponse res = RestContext.response;
    private static requestBody reqBody = new requestBody();
    private static responseBody resBody = new responseBody();
    public static List<String> getPicklistOptions(String fieldApiName) {
        List<String> picklistOptions = new List<String>();
        Schema.DescribeSObjectResult obj_describe_result = Schema.getGlobalDescribe().get('Booking__c').getDescribe() ;
        Map<String,Schema.SObjectField> fields = obj_describe_result.fields.getMap() ;
        Schema.DescribeFieldResult fieldResult = fields.get(fieldApiName).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry pickListVal : ple) {
            picklistOptions.add(pickListVal.getValue());
        }
        return picklistOptions;
    }
    @HttpPost
    global static void run() {
        List<Account> dodlYMH = new List<Account>();
        List<Order> orderCRM = new List<Order>();
        try {
            reqBody = (requestBody)JSON.deserialize(req.requestBody.toString(), requestBody.class);
            
            /*if (String.isBlank(reqBody.Brand)) {
                createResponse('PARAM_NOBRAND');
           		return;
            }*/
            if (String.isBlank(reqBody.Model)) {
                createResponse('PARAM_NOMODEL');
           		return;
            }
            if (String.isBlank(reqBody.FullName)) {
                createResponse('PARAM_NOFULLNAME');
           		return;
            }
            
            if (String.isBlank(reqBody.Mobile)) {
                createResponse('PARAM_NOMOBILE');
           		return;
            }
            
            if (String.isBlank(reqBody.Email)) {
                createResponse('PARAM_NOEMAIL');
           		return;
            }
            
            if (String.isBlank(reqBody.BookingTime)) {
                createResponse('PARAM_NOBOOKINGTIME');
           		return;
            }
            string phoneconvert = StringHelper.normalizePhoneNumber(reqBody.Mobile);
			dodlYMH = [SELECT ID, (SELECT Id FROM Accounts2__r WHERE PersonMobilePhone = : phoneconvert AND Is_Primary__c = FALSE) FROM ACCOUNT 
                       WHERE DO_DL_Code__c =: reqBody.DoDL];
            
            if (dodlYMH.isEmpty()) {
                createResponse('PARAM_DODLNOTFOUND');
                return;
            }
            
            createBookingAppointment(reqBody, dodlYMH);
            // Create a success response.
            createResponse('SUCCESS');
            return;
            
        }
        catch (Exception ex) {
            createResponse('ERROR_EXCEPTION', ex);
            return;
        }        
    }
    
    private static void createBookingAppointment(requestBody reqBody, List<Account> dodlYMH) {
        //List<String> brands = getPicklistOptions('Brand__c');
        List<String> models = getPicklistOptions('Model__c');
        List<String> bookingTimes = getPicklistOptions('Booking_Time__c');
        List<String> serviceTypes = getPicklistOptions('Service_Type__c');
        Booking__c booking = new Booking__c();
        //if (brands.contains(reqBody.Brand)) booking.Brand__c = reqBody.Brand;
        //if (models.contains(reqBody.Model)) booking.Model__c = reqBody.Model;
         booking.Model__c = reqBody.Model;
		booking.Full_Name__c = reqBody.FullName;
        booking.Mobile__c = reqBody.Mobile;
        booking.Email__c = reqBody.Email;
        booking.Adrress__c = reqBody.Adrress;
        booking.Source__c = reqBody.Source;
        booking.Booking_Date__c = Date.valueOf(reqBody.BookingDate);
        if (bookingTimes.contains(reqBody.BookingTime)) booking.Booking_Time__c = reqBody.BookingTime;
        if (serviceTypes.contains(reqBody.ServiceType)) booking.Service_Type__c = reqBody.ServiceType;
        booking.Do_DL__c = dodlYMH[0].Id;
        booking.Account__c = !dodlYMH[0].Accounts2__r.isEmpty() ? dodlYMH[0].Accounts2__r[0].Id : null;
        insert booking;
    }
    
    private static void createResponse(String code) {
		createResponse(code, null);
	}

    private static void createResponse(String code, Exception ex) {
		resBody.responseMessage = err.get(code).errMessage;
		if (ex != null) {
			resBody.responseMessage += ' - ' + ex.getMessage();
		}
        res.addHeader('Access-Control-Allow-Origin', '*');
        res.addHeader('Content-Type', 'application/json');     
        res.statusCode = err.get(code).statusCode;
        res.responseBody = Blob.valueOf(JSON.Serialize(resBody));
    }
    
    global class requestBody {
        global String AppointmentCode {
            get;
            set;
        }
        global String Brand {
            get;
            set;
        }
        global String Model {
            get;
            set;
        }
        global String FullName {
            get;
            set;
        }
        global String Mobile {
            get;
            set;
        }
        global String Source {
            get;
            set;
        }
        global String Email {
            get;
            set;
        }
        global String Adrress {
            get;
            set;
        }
        global String BookingTime {
            get;
            set;
        }
        global String BookingDate {
            get;
            set;
        }
        global String ServiceType {
            get;
            set;
        }
        global String DoDL {
            get;
            set;
        }
    }

    global class responseBody {
        global string responseMessage {
            get;
            set;
        }
    }
    private class errDef {
        Integer statusCode;
        String errMessage;
        errDef (Integer a, String b) {
            statusCode = a;
            errMessage = b;
        }
    }
}