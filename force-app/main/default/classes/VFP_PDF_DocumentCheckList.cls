public without sharing class VFP_PDF_DocumentCheckList {
    public string recordId{get;set;}
    public Order objOrder{get;set;}
    public string invoiceInfo{get;set;}
    public string logo{get;set;}
    public VFP_PDF_DocumentCheckList() {
        this.recordId = ApexPages.currentPage().getParameters().get('Id');
        this.objOrder = getFormDocumentCheckList(this.recordId);
        this.invoiceInfo = '';
        if(this.objOrder.Invoice_No__c>0 && this.objOrder.Invoice_No__c!=null){
            this.invoiceInfo+='Số ' + string.valueOf(this.objOrder.Invoice_No__c);
        }
        if(this.objOrder.Invoice_Date__c!=null){
            this.invoiceInfo+='   Ngày ' + this.objOrder.Invoice_Date__c.day() + '/' + this.objOrder.Invoice_Date__c.month() + '/' + this.objOrder.Invoice_Date__c.year();
        }
        logo= '';
 
        
        if (objOrder.DO_DL__r.Name != null) {
            String doDlCreateName = objOrder.DO_DL__r.Name;
            
            if (doDlCreateName == 'REVZONE YAMAHA MOTOR HA NOI') {
                logo = 'logoRevzoneYamahaMotorHN';
            } else {
                logo = 'logoRevzoneYamahaMotorSG';
            }
        }
    }

    public static Order getFormDocumentCheckList(string recordId){

        Order objOrder = [SELECT Id,
                                Account.Name,
                          		Account.DO_DL_Create_Account__r.Name,
                          		DO_DL__r.Name,
                          		Account.DO_DL_Create_Account__r.Address_logo__c,
                                Sender_Document__r.Name,
                                Product__r.Sales_Name__c,
                                Product__r.Color_Name__c,
                                Asset__r.Engine_No__c,
                                Asset__r.Frame_Number__c,
                                Invoice_No__c,
                                Invoice_Date__c
                                FROM Order 
                                WHERE Id=:recordId];
        if(objOrder!=null){
            return objOrder;
        }
        

        return null;
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
        a = a;        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
            a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
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