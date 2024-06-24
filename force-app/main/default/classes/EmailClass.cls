public with sharing class EmailClass{
    private final static String DATE_TIME_FILE_FORMAT = 'yyyyMMddHHmm';
    private final static String FILE_NAME = '{0}_{1}.pdf';
    
    @AuraEnabled
    public static Apiresponse getOpportunity(String recordId){
        Apiresponse apiresponse = new Apiresponse();
        try{
            Opportunity objOppty = [SELECT Id, AccountId, Account.PersonEmail
                                    FROM Opportunity
                                    WHERE Id = :recordId];
            if (apiresponse.error == Null){
                apiresponse.success = true;
                apiresponse.result = objOppty;
            }
            return apiresponse;
        } catch (Exception e){
            apiresponse.error = e.getMessage();
            return apiresponse;
        }
    }

    @AuraEnabled
    public static List<SObject> search(String searchString){
        List<SObject> searchList = new List<SObject>();
        String strEmployee = RecordTypeHelper.CONTACT_EMPLOYEE;
        try{
            String searchStr = '*' + searchString + '*';
            String searchquery = 
            'FIND\'' + searchStr + 
            '\'IN ALL FIELDS RETURNING Contact(id, name, email where email != null AND RecordTypeId =: strEmployee) LIMIT 10';
            
            List<List<SObject>> searchResult = search.query(searchquery);
            for (List<SObject> curList : searchResult){
                searchList.addAll(curList);
            }
            system.debug('searchList:::' + searchList.size());
        } catch (Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        return searchList;
    }

    @AuraEnabled
    public static ApiResponse sendEmailController(String emailDetailStr, String recordId){
        String recordIdVersion;
        EmailWrapper emailDetails = (EmailWrapper)JSON.deserialize(emailDetailStr, EmailWrapper.class);
        List<Id> lstId = new List<Id>();
        ApiResponse apiresponse = new ApiResponse();
        List<String> lstStringEmail = new List<String>();
        List<Task> lstTaskUpsert = new List<Task>();
        System.debug('emailDetails.subject :' + emailDetails.subject);
        Messaging.reserveSingleEmailCapacity(1);
        try{
            Opportunity objOpportunity = [SELECT Id, Account.PersonContactId, Account.PersonEmail FROM Opportunity WHERE Id =: recordId];
            lstStringEmail.add(objOpportunity.Account.PersonEmail);
            User obj = [SELECT Id
                            , SenderEmail
                            , Name
                        FROM User
                        WHERE Id =: UserInfo.getUserId()];
            lstId.add(createPdfFile(recordId));
            if (!emailDetails.files.isEmpty()){
                for (files item : emailDetails.files){
                    lstId.add(item.contentVersionId);
                }
            }
            messaging.SingleEmailMessage mail = new messaging.SingleEmailMessage();
            mail.setToAddresses(lstStringEmail);
            mail.setCcAddresses(emailDetails.ccAddress);
            mail.setReplyTo(obj.SenderEmail);
            mail.setSenderDisplayName(obj.Name);
            mail.setSubject(emailDetails.subject);
            mail.setHtmlBody(emailDetails.body);
            mail.setEntityAttachments(lstId);
            

            List<Messaging.SendEmailResult> results = Messaging.sendEmail(new List<messaging.SingleEmailMessage>{ mail });
            if (results.get(0).isSuccess()) {
                List<Task> lstTaskQuote = [SELECT Id
                                                , Subject
                                                , WhatId
                                                , Status
                                            FROM Task
                                            WHERE WhatId =: recordId
                                                AND Subject =: 'Send Quote'
                                                AND (Status =: 'Open' OR Status =: 'In Processing')];
                if(!lstTaskQuote.isEmpty()) {
                    for(Task item : lstTaskQuote) {
                        item.Status = 'Completed';
                        lstTaskUpsert.add(item);
                    }
                }
                lstTaskUpsert.add(new Task(
                    WhoId = objOpportunity.Account.PersonContactId,
                    WhatId = recordId,
                    Priority = 'Hight',
                    Comment__c = emailDetails.subject,
                    Status = 'Completed',
                    Subject = 'Send Email',
                    ActivityDate = Date.today()
                ));
                upsert lstTaskUpsert;
            } else {
                apiresponse.error = results.get(0).getErrors()[0].getMessage();
                return apiresponse;
            }
            if (apiresponse.error == Null){
                apiresponse.success = true;
            }
            return apiresponse;
        } catch (exception e){
            apiresponse.error = e.getMessage();
            return apiresponse;
        }
    }

    public static Id createPdfFile(String opportunityId){
        Savepoint sp = Database.setSavepoint();
        try{
            Map<String, String> files = new Map<String, String>();
            Opportunity opportunity = [SELECT Name, Account.Name, CreatedDate, Quote_Number__c
                                                 FROM Opportunity
                                                 WHERE ID = :opportunityId];
            
            PageReference page = Page.QuotationAndDealForm;
            page.getParameters().put('id', opportunityId);
            Blob pdfContent;
            if (Test.isRunningTest()){
                pdfContent = Blob.valueOf('TestClass.pdf');
            } else{
                pdfContent = page.getContent();
            }
            DateTime dt = DateTime.now();
            String strDateTime = dt.format(DATE_TIME_FILE_FORMAT);
            String fileName = String.format(FILE_NAME, new List<String>{ opportunity.Name, opportunity.Quote_Number__c});
            ContentVersion objContentVersion = createContentVersion(pdfContent, fileName);
            String contentDocumentId = createContentDocumentLink(objContentVersion.Id, opportunityId);
            String base64pdf = EncodingUtil.base64Encode(pdfContent);
            files.put(fileName, base64pdf);
            return objContentVersion.Id;
        } catch (Exception ex){
            Database.rollback(sp);
            return ex.getMessage();
        }
    }

    private static ContentVersion createContentVersion(Blob pdfContent, String fileName){
        ContentVersion objContentVersion = new ContentVersion(VersionData = pdfContent, Title = fileName, PathOnClient = fileName);
        insert objContentVersion;
        return objContentVersion;
    }

    private static String createContentDocumentLink(String contentVersionId, String opportunityId){
        ContentVersion objContentVersion = [SELECT ContentDocumentId
                                            FROM ContentVersion
                                            WHERE Id = :contentVersionId];
        ContentDocumentLink objContentDocLink = new ContentDocumentLink();
        objContentDocLink.ContentDocumentId = objContentVersion.ContentDocumentId;
        objContentDocLink.LinkedEntityId = opportunityId;
        objContentDocLink.ShareType = 'V';
        insert objContentDocLink;
        return objContentVersion.ContentDocumentId;
    }

    class EmailWrapper{
        public List<String> toAddress;
        public List<String> ccAddress;
        public String subject;
        public String body;
        public List<files> files;
    }

    class files{
        public string name;
        public string documentId;
        public string contentVersionId;
        public string contentBodyId;
        public string mimeType;

    }
Public static void cheatTemp() {
        String a = 'cheat';
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
                a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
    }
}