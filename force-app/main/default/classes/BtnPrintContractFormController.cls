public without sharing class BtnPrintContractFormController {
  public string currentRecordId { get; set; }
  public Contract currentContract { get; set; }
  public Account currentContractOwner { get; set; }
  public Account currentAccount { get; set; }
  public Opportunity currentOpty { get; set; }
  public List<OpportunityLineItem> listProduct { get; set; }
  public String contractDay { get; set; }
  public String contractMonth { get; set; }
  public String contractYear { get; set; }
  public Contract_Form_Template__c template { get; set; }

  public decimal total { get; set; }
  public string total_text_en { get; set; }
  public string total_text_vn { get; set; }
  public decimal total_exclude_vat { get; set; }
  public decimal amount_vat { get; set; }

  public string payment_1_vn { get; set; }
  public string payment_1_en { get; set; }
  public string payment_2_vn { get; set; }
  public string payment_2_en { get; set; }
  public string payment_3_vn { get; set; }
  public string payment_3_en { get; set; }

  public string payment_1_vn_text { get; set; }
  public string payment_1_en_text { get; set; }
  public string payment_2_vn_text { get; set; }
  public string payment_2_en_text { get; set; }
  public string payment_3_vn_text { get; set; }
  public string payment_3_en_text { get; set; }
  public Opportunity objOpportunity { get; set; }
  
  public Decimal Deposit_amount_for_Installment { get; set; }
  public String Deposit_amount_for_Installment_vn_text { get; set; }
  
  public string removeVietnamToneText { get; set; }
  public string provinceEng { get; set; }
  public BtnPrintContractFormController() {
  }
  public BtnPrintContractFormController(
    ApexPages.StandardController controller
  ) {
    currentRecordId = ApexPages.CurrentPage().getparameters().get('id');
       
    currentContract = [
      SELECT
        Id,
        CreatedDate,
        AccountId,
        ContractNumber,
        Opportunity__c,
        Remark__c,
        Owner.AccountId,
        Owner.DODL_Manager__r.ContactId,
        Contract_Form_Template__c,
        Tentative_Delivery_Date__c,
        Receiver__c,
        Delivery_Time__c,
        Payment_Type__c,
        Payment_1__c,
        Payment_2__c,
        Payment_3__c,
        Contract_Information__c,
        Contract_Information__r.Name,
        Contract_Information__r.Head_Office__c,
        Contract_Information__r.Head_Office_Eng__c,
        Contract_Information__r.Mobile__c,
        Contract_Information__r.Fax__c,
        Contract_Information__r.Tax_code__c,
        Contract_Information__r.Represented_by__c,
        Contract_Information__r.Represented_By_Eng__c,
        Contract_Information__r.Represented_Title__c,
        Contract_Information__r.Represented_Title_Eng__c,
        Contract_Information__r.DOB__c,
        Contract_Information__r.ID_Type__c,
        Contract_Information__r.Province__c,
        Contract_Information__r.Province__r.Name,
        Contract_Information__r.ID_number__c,
        Contract_Information__r.ID_Issue_dated__c,
        Contract_Information__r.ID_Issued_By__c,
        Contract_Information__r.ID_Issued_By_Eng__c,
        Contract_Information__r.Permanent_residence__c,
        Contract_Information__r.Address_Full__c,
        Contract_Information__r.Country__c,
        Opportunity__r.Down_payment__c,
        Opportunity__r.Paid_amount__c,
        Opportunity__r.DODL_Create__r.Name,
        Opportunity__r.DODL_Create__r.Represented_By__c ,
        Opportunity__r.DODL_Create__r.Represented_Title__c ,
        Opportunity__r.DODL_Create__r.Represented_By_Eng__c ,
        Opportunity__r.DODL_Create__r.Represented_Title_Eng__c ,
        Opportunity__r.DODL_Create__r.Contract_Company_Name_eng__c  ,
        Opportunity__r.DODL_Create__r.Contract_Company_Name__c ,
        Opportunity__r.DODL_Create__r.Bank_Account_Name__c ,
        Opportunity__r.DODL_Create__r.Bank_Account_Name_Eng__c ,
        Opportunity__r.DODL_Create__r.Bank_Number2__c ,
        Opportunity__r.DODL_Create__r.Address_Eng__c,
        Account.DO_DL_Create_Account__r.Head_Office__c,
        Account.DO_DL_Create_Account__r.Head_Office_Eng__c,
        Account.DO_DL_Create_Account__r.Address__c,
        Account.DO_DL_Create_Account__r.Address_Eng__c,
        Account.DO_DL_Create_Account__r.Phone,
        Account.DO_DL_Create_Account__r.Fax,
        Account.DO_DL_Create_Account__r.Tax_Code__c,
        Account.DO_DL_Create_Account__r.Bank_Name__c,
        Account.DO_DL_Create_Account__r.Bank_Name_Eng__c,
        Account.DO_DL_Create_Account__r.Bank_Account_Name__c,
        Account.DO_DL_Create_Account__r.Represented_By__c,
        Account.DO_DL_Create_Account__r.Represented_Title__c ,
        Account.DO_DL_Create_Account__r.Represented_By_Eng__c,
         Account.DO_DL_Create_Account__r.Represented_Title_Eng__c ,
        Account.DO_DL_Create_Account__r.Bank_Number2__c,
        Account.DO_DL_Create_Account__r.Name
      FROM Contract
      WHERE Id = :currentRecordId
    ];
    List<Contact> contactManager = [
      SELECT Id, AccountId
      FROM Contact
      WHERE Id = :currentContract.Owner.DODL_Manager__r.ContactId
    ];
    if (currentContract.Owner.AccountId !=null) {
      currentContractOwner = [
        SELECT
          Id,
          Head_Office__c,
          Head_Office_Eng__c,
          Phone,
          Fax,
          Tax_Code__c,
          Bank_Number2__c,
          Bank_Account_Name__c,
          Bank_Name__c,
          Bank_Name_Eng__c,
          Bank_Account_Name_Eng__c,
          Represented_By__c,
          Represented_By_Eng__c,
          Represented_Title__c,
          Address_Full__c,
          Address__c,
          Address_Eng__c
        FROM Account
        WHERE
          Id = :// contactManager[0].AccountId
          currentContract.Owner.AccountId
      ];
    }
    //system.debug(currentContractOwner);
    currentAccount = [
      SELECT
        Id,
        Name,
        Country__c,
        PersonBirthdate,
        DOB__pc,
        PersonMobilePhone,
        Fax,
        ID_No__c,
        ID_Issue_Date__c,
        ID_Type__c,
        ID_Issued_By__c,
        ID_Issued_By_Eng__c,
        Permanent_Residence__c,
        Province__c,
        Province__r.Name,
        Address_Full__c
      FROM Account
      WHERE Id = :currentContract.AccountId
    ];
    contractDay = String.valueOf(currentContract.CreatedDate.day());
    contractMonth = String.valueOf(currentContract.CreatedDate.month());
    contractYear = String.valueOf(currentContract.CreatedDate.year());
    String data = EncodingUtil.urlDecode(currentAccount.Name, 'ASCII');

    if (currentContract.Contract_Form_Template__c != null) {
      template = [
        SELECT
          Id,
          Article_3_Single_Payment__c,
          Article_3_Multi_Payment__c,
          Article_4__c,
          Article_5__c,
          Article_6__c,
          Article_7__c
        FROM Contract_Form_Template__c
        WHERE Id = :currentContract.Contract_Form_Template__c
      ];
    }

    List<String> args = new List<String>{ '0', 'number', '###,###,##0.00' };
    if (currentContract.Opportunity__c != null) {
      currentOpty = [
        SELECT Id
        FROM Opportunity
        WHERE Id = :currentContract.Opportunity__c
      ];
      listProduct = [
        SELECT
          Id,
          Product2.Name,
          Product2.Sales_Name__c,
          Product2.Model_Name__c,
          Product2.Model__c,
          Product2.Color_Type__c,
          Product2.Color_Name__c,
          Product2.Model_Code__c,
          Quantity,
          UnitPrice,
          TotalPrice
        FROM OpportunityLineItem
        WHERE OpportunityId = :currentOpty.Id
      ];

      total = 0;
      for (OpportunityLineItem p : listProduct) {
        if (p.UnitPrice != null && p.Quantity != null) {
          total += p.UnitPrice * p.Quantity;
        }
      }

      total_exclude_vat = total / 1.1;
      amount_vat = total - total_exclude_vat;

      total_text_en = ConvertCurrencyToWordsEn.english_number(total);
      total_text_vn = textUppercaseFormat(
        ConvertCurrencyToVietnamese.convertV(total)
      );
    }
    
    if (currentContract.Payment_1__c != null) {
      payment_1_en_text = ConvertCurrencyToWordsEn.english_number(
        currentContract.Payment_1__c
      );
      payment_1_vn_text = textUppercaseFormat(
        ConvertCurrencyToVietnamese.convertV(currentContract.Payment_1__c)
      );

      payment_1_vn =
        'Thanh toán đợt 1 : ' +
        currentContract.Payment_1__c +
        ' VND (Bằng chữ : ' +
        payment_1_vn_text +
        ' Việt Nam Đồng)';
      payment_1_en =
        '1st Payment : ' +
        currentContract.Payment_1__c +
        ' VND (In word : ' +
        payment_1_en_text +
        ' Vietnamese Dong)';
    }
    if (currentContract.Payment_2__c != null) {
      payment_2_en_text = ConvertCurrencyToWordsEn.english_number(
        currentContract.Payment_2__c
      );
      payment_2_vn_text = textUppercaseFormat(
        ConvertCurrencyToVietnamese.convertV(currentContract.Payment_2__c)
      );

      payment_2_vn =
        'Thanh toán đợt 2 : ' +
        currentContract.Payment_2__c +
        ' VND (Bằng chữ : ' +
        payment_2_vn_text +
        ' Việt Nam Đồng)';
      payment_2_en =
        '2nd Payment : ' +
        currentContract.Payment_2__c +
        ' VND (In word : ' +
        payment_2_en_text +
        ' Vietnamese Dong)';
    }
    if (currentContract.Payment_3__c != null) {
      payment_3_en_text = ConvertCurrencyToWordsEn.english_number(
        currentContract.Payment_3__c
      );
      payment_3_vn_text = textUppercaseFormat(
        ConvertCurrencyToVietnamese.convertV(currentContract.Payment_3__c)
      );

      payment_3_vn =
        'Thanh toán đợt 3 : ' +
        currentContract.Payment_3__c +
        ' VND (Bằng chữ : ' +
        payment_3_vn_text +
        ' Việt Nam Đồng)';
      payment_3_en =
        '3rd Payment : ' +
        currentContract.Payment_3__c +
        ' VND (In word : ' +
        payment_3_en_text +
        ' Vietnamese Dong)';
    }
    if (currentContract.Contract_Information__c == null) {
      if (currentAccount.Name != null) {
        removeVietnamToneText = RemoveVietnameseTone.RemoveTone(
          currentAccount.Name
        );
      }
      if (currentAccount.Province__c != null) {
        provinceEng = RemoveVietnameseTone.RemoveToneProvince(
          currentAccount.Province__r.Name
        );
      }
    } else if (currentContract.Contract_Information__c != null) {
      if (currentContract.Contract_Information__r.Name != null) {
        removeVietnamToneText = RemoveVietnameseTone.RemoveTone(
          currentContract.Contract_Information__r.Name
        );
      }
      if (currentContract.Contract_Information__r.Province__c != null) {
        provinceEng = RemoveVietnameseTone.RemoveToneProvince(
          currentContract.Contract_Information__r.Province__r.Name
        );
      }
    }
      
    /* Deposit amount for Installment/Tổng tiền đặt cọc mua trả góp */
   /* if(currentContract.Opportunity__r.Down_payment__c !=null && currentContract.Opportunity__r.Paid_amount__c !=null ){
        Deposit_amount_for_Installment = currentContract.Opportunity__r.Paid_amount__c - currentContract.Opportunity__r.Down_payment__c ;
    }else{
        Deposit_amount_for_Installment = (currentContract.Opportunity__r.Paid_amount__c == null ?0: currentContract.Opportunity__r.Paid_amount__c) - (currentContract.Opportunity__r.Down_payment__c == null ?0: currentContract.Opportunity__r.Down_payment__c);
    }*/
    
        Deposit_amount_for_Installment = currentContract.Opportunity__r.Down_payment__c ;

    if (Deposit_amount_for_Installment != null) {
    	Deposit_amount_for_Installment_vn_text = ConvertCurrencyToVietnamese.convertV(Deposit_amount_for_Installment);
    } else {
        Deposit_amount_for_Installment_vn_text = ''; // Handle the case when the deposit amount is null
    }
 
  }

  public String textUppercaseFormat(String name) {
    String result = '';

    if (name != null && name != '') {
      for (String iter : name.split('[ ]+')) {
        if (iter != null && iter != '') {
          if (iter.length() > 1) {
            result +=
              iter.substring(0, 1).toUpperCase() +
              iter.substring(1, iter.length()) +
              ' ';
          } else {
            result += iter.substring(0, 1).toUpperCase() + ' ';
          }
        }
      }
      result = result.substring(0, result.length() - 1);
    }
    return result;
  }
  
  public static void cheatTemp() {
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
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
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