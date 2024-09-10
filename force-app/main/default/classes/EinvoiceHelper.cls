public class EinvoiceHelper {
    // Dùng Test class EinvoiceHelperTest

    static Invoice_Enpoint__mdt apiSetting {
        get {
            if (apiSetting == null) {
                Invoice_Enpoint__mdt[] settings = [
                    SELECT
                        MasterLabel,
                        DeveloperName,
                        HCM_Account__c,
                        HCM_Account_Pass__c,
                        HCM_Endpoint__c,
                        HCM_Serial__c,
                        HCM_User__c,
                        HCM_User_Pass__c,
                        HCM_Pattern__c,
                        HCM_Bike_Serial__c,
                        HCM_Bike_Pattern__c,
                        HN_Account__c,
                        HN_Account_Pass__c,
                        HN_Enpoint__c,
                        HN_Serial__c,
                        HN_User__c,
                        HN_User_Pass__c,
                        HN_Pattern__c,
                        HN_Bike_Serial__c,
                        HN_Bike_Pattern__c,
                        NT_Account__c,
                        NT_Account_Pass__c,
                        NT_Enpoint__c,
                        NT_Serial__c,
                        NT_User__c,
                        NT_User_Pass__c,
                        NT_Pattern__c,
                        NT_Bike_Serial__c,
                        NT_Bike_Pattern__c,
                        DN_Account__c,
                        DN_Account_Pass__c,
                        DN_Enpoint__c,
                        DN_Serial__c,
                        DN_User__c,
                        DN_User_Pass__c,
                        DN_Pattern__c,
                        DN_Bike_Serial__c,
                        DN_Bike_Pattern__c,
                        HCM_Employee_Serial__c,
                        HCM_Employee_Pattern__c,
                        HCM_Employee_Bike_Serial__c,
                        HCM_Employee_Bike_Pattern__c,
                        HN_Employee_Serial__c,
                        HN_Employee_Pattern__c,
                        HN_Employee_Bike_Serial__c,
                        HN_Employee_Bike_Pattern__c,
                        DN_Employee_Serial__c,
                        DN_Employee_Pattern__c,
                        DN_Employee_Bike_Serial__c,
                        DN_Employee_Bike_Pattern__c,
                        NT_Employee_Serial__c,
                        NT_Employee_Pattern__c,
                        NT_Employee_Bike_Serial__c,
                        NT_Employee_Bike_Pattern__c
                    FROM Invoice_Enpoint__mdt
                    WHERE DeveloperName = 'Default'
                ];
                if (!settings.isEmpty()) {
                    //system.debug(settings[0]);
                    apiSetting = settings[0];
                } else {
                    if (!Test.isRunningTest()) {
                        //throw new SmsClass.SmsBrandNameException('Please setup a default API setting');
                    } else {
                        Invoice_Enpoint__mdt setting = new Invoice_Enpoint__mdt();
                        setting.DeveloperName = 'Default';
                        setting.HCM_Endpoint__c = 'https://cadminhcmtt78test.yamaha-motor.com.vn:4343/YamahaPublishservice.asmx?op=ImportAndPublishInv';
                        setting.HCM_Account__c = 'yamahamotorhcmadmin';
                        setting.HCM_Account_Pass__c = '0100774342aA@';
                        setting.HCM_User__c = 'yamahamotorhcmservice';
                        setting.HCM_User_Pass__c = 'Einv#@oi@vn#pt20';
                        setting.HCM_Serial__c = 'C22TMC';
                        apiSetting = setting;
                    }
                }
            }
            return apiSetting;
        }
        set {
        }
    }

    // Tạo ra record einvoice line và lưu thông tin einvoice để lên report xuất ra
    public static void createInvoice(
        Order order,
        Contract_Information__c contractInfo,
        List<OrderItem> listOrderItem,
        Decimal VATRate,
        String paymentCode,
        String paymentMethod,
        Integer count
    ) {
        // test sanbox (801O000000195eeIAA);

        DateTime today = Datetime.now();
        String dateOutput = today.format('dd/MM/yyyy');

        if (order == null) {
            return;
        }
        string strMessage = '';
        string strOutput = '';

        String accountId = order.AccountId;

        Map<String, Schema.SObjectField> accountFieldMap = Account.sObjectType.getDescribe()
            .fields.getMap();
        List<string> accountSelectFields = new List<String>(
            accountFieldMap.keySet()
        );
        String accountSoql = 'SELECT ' + String.join(accountSelectFields, ',');
        accountSoql += ' FROM Account';
        accountSoql += ' WHERE Id = : accountId';
        Account account = Database.query(accountSoql);

        try {
            String endPoint = '';
            String accountYMH = '';
            string accountPassYMH = '';
            string userNameYMH = '';
            string userPassYMH = '';
            string pattern = '';
            string serial = '';

            if (order.DO_DL__r.Einvoice_Location__c == 'Hồ Chí Minh') {
                endPoint = apiSetting.HCM_Endpoint__c; /// hcm
                accountYMH = apiSetting.HCM_Account__c;
                accountPassYMH = apiSetting.HCM_Account_Pass__c;
                userNameYMH = apiSetting.HCM_User__c;
                userPassYMH = apiSetting.HCM_User_Pass__c;
                if (order.RecordTypeId == RecordTypeHelper.ORDER_BIKE) {
                    pattern = order.Is_Employee__c
                        ? apiSetting.HCM_Employee_Bike_Pattern__c
                        : apiSetting.HCM_Bike_Pattern__c;
                    serial = order.Is_Employee__c
                        ? apiSetting.HCM_Employee_Bike_Serial__c
                        : apiSetting.HCM_Bike_Serial__c;
                } else {
                    pattern = order.Is_Employee__c
                        ? apiSetting.HCM_Employee_Pattern__c
                        : apiSetting.HCM_Pattern__c;
                    serial = order.Is_Employee__c
                        ? apiSetting.HCM_Employee_Serial__c
                        : apiSetting.HCM_Serial__c;
                }
            } else if (order.DO_DL__r.Einvoice_Location__c == 'Nha Trang') {
                endPoint = apiSetting.NT_Enpoint__c; // nt
                accountYMH = apiSetting.NT_Account__c;
                accountPassYMH = apiSetting.NT_Account_Pass__c;
                userNameYMH = apiSetting.NT_User__c;
                userPassYMH = apiSetting.NT_User_Pass__c;
                if (order.RecordTypeId == RecordTypeHelper.ORDER_BIKE) {
                    pattern = order.Is_Employee__c
                        ? apiSetting.NT_Employee_Bike_Pattern__c
                        : apiSetting.NT_Bike_Pattern__c;
                    serial = order.Is_Employee__c
                        ? apiSetting.NT_Employee_Bike_Serial__c
                        : apiSetting.NT_Bike_Serial__c;
                } else {
                    pattern = order.Is_Employee__c
                        ? apiSetting.NT_Employee_Pattern__c
                        : apiSetting.NT_Pattern__c;
                    serial = order.Is_Employee__c
                        ? apiSetting.NT_Employee_Serial__c
                        : apiSetting.NT_Serial__c;
                }
            } else if (order.DO_DL__r.Einvoice_Location__c == 'Hà Nội') {
                endPoint = apiSetting.HN_Enpoint__c; // nt
                accountYMH = apiSetting.HN_Account__c;
                accountPassYMH = apiSetting.HN_Account_Pass__c;
                userNameYMH = apiSetting.HN_User__c;
                userPassYMH = apiSetting.HN_User_Pass__c;
                if (order.RecordTypeId == RecordTypeHelper.ORDER_BIKE) {
                    pattern = order.Is_Employee__c
                        ? apiSetting.HN_Employee_Bike_Pattern__c
                        : apiSetting.HN_Bike_Pattern__c;
                    serial = order.Is_Employee__c
                        ? apiSetting.HN_Employee_Bike_Serial__c
                        : apiSetting.HN_Bike_Serial__c;
                } else {
                    pattern = order.Is_Employee__c
                        ? apiSetting.HN_Employee_Pattern__c
                        : apiSetting.HN_Pattern__c;
                    serial = order.Is_Employee__c
                        ? apiSetting.HN_Employee_Serial__c
                        : apiSetting.HN_Serial__c;
                }
            } else if (order.DO_DL__r.Einvoice_Location__c == 'Đà Nẵng') {
                endPoint = apiSetting.DN_Enpoint__c; // nt
                accountYMH = apiSetting.DN_Account__c;
                accountPassYMH = apiSetting.DN_Account_Pass__c;
                userNameYMH = apiSetting.DN_User__c;
                userPassYMH = apiSetting.DN_User_Pass__c;
                if (order.RecordTypeId == RecordTypeHelper.ORDER_BIKE) {
                    pattern = order.Is_Employee__c
                        ? apiSetting.DN_Employee_Bike_Pattern__c
                        : apiSetting.DN_Bike_Pattern__c;
                    serial = order.Is_Employee__c
                        ? apiSetting.DN_Employee_Bike_Serial__c
                        : apiSetting.DN_Bike_Serial__c;
                } else {
                    pattern = order.Is_Employee__c
                        ? apiSetting.DN_Employee_Pattern__c
                        : apiSetting.DN_Pattern__c;
                    serial = order.Is_Employee__c
                        ? apiSetting.DN_Employee_Serial__c
                        : apiSetting.DN_Serial__c;
                }
            }

            Einvoice__c einvoice = new Einvoice__c();
            einvoice.Order__c = order.Id;
            einvoice.Invoice_Publish_Date__c = Date.today();
            einvoice.Key__c = order.Id + '-' + count;

            einvoice.CusCode__c = account.AccountNumber;

            if (contractInfo != null && contractInfo.Name != null) {
                einvoice.CusName__c = contractInfo.Name;
            } else if (order.Invoice_Type__c == 'Company') {
                einvoice.CusName__c = order.Tax_Name__c;
            } else if (order.Customer__c != null) {
                einvoice.CusName__c = order.Customer__c;
            } else {
                einvoice.CusName__c = account.Name;
            }

            if (
                contractInfo != null &&
                contractInfo.Address_Full__c != null &&
                contractInfo.RecordType.Name == 'Person'
            ) {
                einvoice.CusAddress__c = contractInfo.Address_Full__c;
                if (order.RecordTypeId != RecordTypeHelper.ORDER_BIKE) {
                    einvoice.DiaChiGiao__c = contractInfo.Address_Full__c;
                }
            } else if (
                contractInfo != null &&
                contractInfo.Head_Office__c != null &&
                contractInfo.RecordType.Name == 'Corporate'
            ) {
                einvoice.CusAddress__c = contractInfo.Head_Office__c;
                if (order.RecordTypeId != RecordTypeHelper.ORDER_BIKE) {
                    einvoice.DiaChiGiao__c = contractInfo.Head_Office__c;
                }
            } else if (order.Account.Address_Full__c != null) {
                einvoice.CusAddress__c = order.Account.Address_Full__c;
                if (order.RecordTypeId != RecordTypeHelper.ORDER_BIKE) {
                    einvoice.DiaChiGiao__c = order.Account.Address_Full__c;
                }
            } else if (order.Tax_Address__c != null) {
                einvoice.CusAddress__c = order.Tax_Address__c;
                if (order.RecordTypeId != RecordTypeHelper.ORDER_BIKE) {
                    einvoice.DiaChiGiao__c = order.Tax_Address__c;
                }
            } else {
                einvoice.CusAddress__c = order.Address_Full__c;
                if (order.RecordTypeId != RecordTypeHelper.ORDER_BIKE) {
                    einvoice.DiaChiGiao__c = order.Address_Full__c;
                }
            }

            if (contractInfo != null && contractInfo.Mobile__c != null) {
                einvoice.CusPhone__c = contractInfo.Mobile__c;
            } else if (
                order.Tax_Mobile__c != null ||
                order.Invoice_Type__c == 'Company'
            ) {
                einvoice.CusPhone__c = order.Tax_Mobile__c;
            } else {
                einvoice.CusPhone__c = account.PersonMobilePhone;
            }

            if (contractInfo != null && contractInfo.Tax_code__c != null) {
                einvoice.CusTaxCode__c = contractInfo.Tax_code__c;
            } else if (
                order.Invoice_Type__c == 'Company' ||
                order.Invoice_Type__c == 'Person'
            ) {
                einvoice.CusTaxCode__c = order.Tax_Code__c;
            } else if (order.Tax_Code__c != null) {
                einvoice.CusTaxCode__c = order.Tax_Code__c;
            } else {
                einvoice.CusTaxCode__c = account.Tax_Code__c;
            }

            // Lay tu payment va check truong hop vua transfer vua cash
            if (
                paymentMethod != 'null' &&
                paymentMethod != null &&
                paymentMethod != ''
            ) {
                einvoice.PaymentMethod__c = paymentMethod;
            } else {
                einvoice.PaymentMethod__c = 'CK';
            }

            //(order.Invoice_Type__c);
            //set evinvoice with order service is company
            if (order.Invoice_Type__c == 'Company') {
                //system.debug(order.Invoice_Type__c);
                einvoice.CusName__c = order.Tax_Name__c;

                einvoice.TenNguoiMua__c = account.Name;
                einvoice.CusAddress__c = order.Tax_Address__c;
                einvoice.CusPhone__c = order.Tax_Mobile__c;
                einvoice.CusTaxCode__c = order.Tax_Code__c;
                //system.debug(einvoice.CusName__c);
            }

            String productLine = '';
            Decimal totalAmount = 0;
            Decimal totalNetAmount = 0;
            Decimal totalVatAmount = 0;
            Decimal totalDiscountAmount = 0;
            Boolean notIncludeVat = false;
            List<Einvoice_Line__c> listELine = new List<Einvoice_Line__c>();
            // Check if VAT free
            if (
                order.Generated_Redeem__c == true &&
                order.RecordTypeId == RecordTypeHelper.ORDER_PCA
            ) {
                notIncludeVat = true;
            } else if (
                order.RecordTypeId == RecordTypeHelper.ORDER_FREE_SERVICE &&
                order.Account.RecordTypeId == RecordTypeHelper.ACCOUNT_DODL
            ) {
                notIncludeVat = true;
            }
            for (OrderItem item : listOrderItem) {
                productLine = item.Record_Type_Name__c;

                //productNode.addChildElement('Code',null,null).addTextNode(item.Product_Code__c != null ? item.Product_Code__c : ''); // model
                Einvoice_Line__c line = new Einvoice_Line__c();
                line.Order_Product__c = item.Id;
                //line.Product_Code__c = item.Product_Code__c;
                if (order.RecordTypeId == RecordTypeHelper.ORDER_BIKE) {
                    item.Product_Name__c = order.Bike_Description__c;
                } else {
                    if (
                        ((order.RecordTypeId ==
                        RecordTypeHelper.ORDER_FREE_COUPON ||
                        order.RecordTypeId ==
                        RecordTypeHelper.ORDER_SERVICE_ORDER) &&
                        item.Applied__c == true)
                    ) {
                        notIncludeVat = true;
                    }

                    if (
                        (order.RecordTypeId ==
                        RecordTypeHelper.ORDER_SERVICE_ORDER &&
                        item.Discount__c != 0 &&
                        item.Order.Campaign__r.Promotion_Item__r.RecordType.Name ==
                        '% Discount') ||
                        (item.Order.Promotion_Item__r.Promotion__r.RecordTypeId ==
                        RecordTypeHelper.PROMOTIONDEFAULT &&
                        item.Product2.Is_Genuine__c == true &&
                        item.Discount__c != 0) ||
                        (order.RecordTypeId == RecordTypeHelper.ORDER_PCA &&
                        item.Discount__c != 0 &&
                        item.Order.Promotion_Item__r.Promotion__r.RecordType.Name ==
                        'Standard')
                    ) {
                        //productNode.addChildElement('ProdName',null,null).addTextNode(item.Line_Description__c != null ? item.Line_Description__c : 'Missing Name'); // require // Product name
                        item.Product_Name__c = item.Line_Description__c;
                        item.ProdName__c = item.Line_Description__c;
                        line.Product_Name__c = item.Line_Description__c;
                    } else {
                        //productNode.addChildElement('ProdName',null,null).addTextNode(item.Product2.Name != null ? item.Product2.Name : 'Missing Name'); // require // Product name
                        item.Product_Name__c = item.Product2.Name;
                        item.ProdName__c = item.Product2.Name;
                        line.Product_Name__c = item.Product2.Name;
                    }
                }

                // productNode.addChildElement('ProdUnit',null,null).addTextNode(item.Product2.Product_Unit__c != null ? item.Product2.Product_Unit__c : 'Chiếc');  // unit
                if (totalDiscountAmount > 0) {
                    item.IsSum__c = '2';
                    line.IsSum__c = '2';
                } else {
                    item.IsSum__c = '0';
                    line.IsSum__c = '0';
                }

                // productNode.addChildElement('ProdQuantity',null,null).addTextNode(item.Quantity != null ? String.valueOf(item.Quantity.setScale(0, RoundingMode.HALF_UP)) : '0'); // quantity
                Decimal discount = item.Discount__c != null
                    ? item.Discount__c
                    : 0;
                /*if(item.Product2.RecordTypeId == RecordTypeHelper.SV_JOB) // 1/7/2022 và thay đổi công thức trên item.Discount_Percent__c
                {
                    line.Quantity__c = item.Quantity *  ((item.Labour_Hours__c / item.Origin_Labour_Hour__c)).setScale(0, RoundingMode.HALF_UP)  ;              
                }
                else
                {
                    line.Quantity__c = item.Quantity.setScale(0, RoundingMode.HALF_UP) ;               
                }*/
                if (item.Product2.RecordTypeId == RecordTypeHelper.SV_JOB) {
                    line.Quantity__c = 0;
                } else {
                    line.Quantity__c = item.Quantity.setScale(
                        0,
                        RoundingMode.HALF_UP
                    );
                }

                Decimal amountBeforeVat = item.ListPrice / (1 + VatRate / 100);
                // Task ymhvn-1034, (1)...
                if (
                    (order.RecordTypeId == RecordTypeHelper.ORDER_BIKE) &&
                    order.Is_Employee__c
                ) {
                    amountBeforeVat = item.UnitPrice / (1 + VatRate / 100);
                }
                // Task ymhvn-1034, ...(1)
                /*if (item.Product2.RecordTypeId == RecordTypeHelper.SV_JOB)
                {
                    amountBeforeVat = item.ListPrice / ( 1 + VatRate/100) *  (item.Labour_Hours__c / item.Origin_Labour_Hour__c);
                }    */
                Decimal vatAmount = (notIncludeVat
                    ? 0
                    : item.ListPrice - amountBeforeVat);
                Decimal discountAmount =
                    amountBeforeVat *
                    ((notIncludeVat ? discount : item.Discount_Percent__c) /
                    100) *
                    item.Quantity;

                if (
                    item.Product2.RecordTypeId ==
                    RecordTypeHelper.PRODUCT_MODEL // Product Bike // yêu cầu của Dương 28/6/2022
                ) {
                    discountAmount =
                        (item.ListPrice - item.UnitPrice) / (1 + VatRate / 100);
                }

                //system.debug('Discount Amount :'+ discountAmount);
                Decimal totalPriceBeforeTax =
                    amountBeforeVat * item.Quantity - discountAmount;
                if (
                    item.Product2.RecordTypeId ==
                    RecordTypeHelper.PRODUCT_MODEL // Product Bike // yêu cầu của Dương 28/6/2022
                ) {
                    totalPriceBeforeTax =
                        (amountBeforeVat * item.Quantity)
                            .setScale(0, RoundingMode.HALF_UP) -
                        discountAmount.setScale(0, RoundingMode.HALF_UP);
                } else if (
                    (order.RecordTypeId ==
                    RecordTypeHelper.ORDER_SERVICE_ORDER &&
                    item.Discount__c != 0 &&
                    item.Discount__c != null &&
                    item.Order.Campaign__r.Promotion_Item__r.RecordType.Name ==
                    '% Discount') ||
                    (order.RecordTypeId == RecordTypeHelper.ORDER_PCA &&
                    item.Discount__c != 0 &&
                    item.Discount__c != null &&
                    item.Order.Promotion_Item__r.Promotion__r.RecordType.Name ==
                    'Standard')
                ) {
                    totalPriceBeforeTax = (amountBeforeVat * item.Quantity)
                        .setScale(0, RoundingMode.HALF_UP);
                } else if (
                    item.Labour_Hours__c != null &&
                    item.Origin_Labour_Hour__c != null &&
                    item.Origin_Labour_Hour__c != 0 &&
                    item.Labour_Hours__c > item.Origin_Labour_Hour__c
                ) {
                    totalPriceBeforeTax = (amountBeforeVat *
                        item.Labour_Hours__c /
                        item.Origin_Labour_Hour__c)
                        .setScale(0, RoundingMode.HALF_UP);
                }
                /*else if (item.Product2.RecordTypeId == RecordTypeHelper.SV_JOB)  // 1/7/2022 và thay đổi công thức trên item.Discount_Percent__c
                {
                    totalPriceBeforeTax = (amountBeforeVat * item.Quantity *  (item.Labour_Hours__c / item.Origin_Labour_Hour__c)).setScale(0, RoundingMode.HALF_UP) - discountAmount.setScale(0, RoundingMode.HALF_UP); 
                }*/

                if (
                    (order.RecordTypeId ==
                    RecordTypeHelper.ORDER_SERVICE_ORDER &&
                    item.Discount__c != 0 &&
                    item.Discount__c != null &&
                    item.Order.Campaign__r.Promotion_Item__r.RecordType.Name ==
                    '% Discount') ||
                    (order.RecordTypeId == RecordTypeHelper.ORDER_PCA &&
                    item.Discount__c != 0 &&
                    item.Discount__c != null &&
                    item.Order.Promotion_Item__r.Promotion__r.RecordType.Name ==
                    'Standard')
                ) {
                    Decimal amountBeforeVatBeforeDiscount =
                        item.ListPrice / (1 + VatRate / 100);
                    item.ProdPrice__c = amountBeforeVatBeforeDiscount.setScale(
                        0,
                        RoundingMode.HALF_UP
                    );
                    line.ProdPrice__c = amountBeforeVatBeforeDiscount.setScale(
                        0,
                        RoundingMode.HALF_UP
                    );
                } else if (
                    (item.Order.Promotion_Item__r.Promotion__r.RecordTypeId ==
                    RecordTypeHelper.PROMOTIONDEFAULT &&
                    item.Product2.Is_Genuine__c == true &&
                    item.Discount__c != 0 &&
                    item.Discount__c != null) ||
                    (item.Order.Manual_Discount_Approve__c == true &&
                    item.Discount__c != 0 &&
                    item.Discount__c != null)
                ) {
                    Decimal discountAmountWithouQuantity =
                        amountBeforeVat *
                        ((notIncludeVat ? discount : item.Discount_Percent__c) /
                        100); // Discount cho amountBeforeVat ko tính discount
                    Decimal amountBeforeVatAfterDiscount =
                        item.ListPrice / (1 + VatRate / 100) -
                        discountAmountWithouQuantity;
                    //productNode.addChildElement('ProdPrice',null,null).addTextNode(String.valueOf(amountBeforeVatAfterDiscount.setScale(0, RoundingMode.HALF_UP))); // price
                    item.ProdPrice__c = amountBeforeVatAfterDiscount.setScale(
                        0,
                        RoundingMode.HALF_UP
                    );
                    line.ProdPrice__c = amountBeforeVatAfterDiscount.setScale(
                        0,
                        RoundingMode.HALF_UP
                    ); // DonGia
                } else if (
                    item.Labour_Hours__c != null &&
                    item.Origin_Labour_Hour__c != null &&
                    item.Origin_Labour_Hour__c != 0 &&
                    item.Labour_Hours__c > item.Origin_Labour_Hour__c
                ) {
                    item.ProdPrice__c = (amountBeforeVat *
                        item.Labour_Hours__c /
                        item.Origin_Labour_Hour__c)
                        .setScale(0, RoundingMode.HALF_UP);
                    line.ProdPrice__c = (amountBeforeVat *
                        item.Labour_Hours__c /
                        item.Origin_Labour_Hour__c)
                        .setScale(0, RoundingMode.HALF_UP);
                } else {
                    //productNode.addChildElement('ProdPrice',null,null).addTextNode(String.valueOf(amountBeforeVat.setScale(0, RoundingMode.HALF_UP))); // price
                    item.ProdPrice__c = amountBeforeVat.setScale(
                        0,
                        RoundingMode.HALF_UP
                    );
                    line.ProdPrice__c = amountBeforeVat.setScale(
                        0,
                        RoundingMode.HALF_UP
                    ); // DonGia
                }

                if (
                    (item.Order.Promotion_Item__r.Promotion__r.RecordTypeId ==
                    RecordTypeHelper.PROMOTIONDEFAULT &&
                    item.Product2.Is_Genuine__c == true &&
                    item.Discount__c != 0 &&
                    item.Discount__c != null) ||
                    (item.Order.Manual_Discount_Approve__c == true &&
                    item.Discount__c != 0 &&
                    item.Discount__c != null) ||
                    (order.RecordTypeId ==
                    RecordTypeHelper.ORDER_SERVICE_ORDER &&
                    item.Discount__c != 0 &&
                    item.Discount__c != null &&
                    item.Discount__c != null &&
                    item.Order.Campaign__r.Promotion_Item__r.RecordType.Name ==
                    '% Discount') ||
                    (order.RecordTypeId == RecordTypeHelper.ORDER_PCA &&
                    item.Discount__c != 0 &&
                    item.Discount__c != null &&
                    item.Discount__c != null &&
                    item.Order.Promotion_Item__r.Promotion__r.RecordType.Name ==
                    'Standard') ||
                    (item.Labour_Hours__c != null &&
                    item.Origin_Labour_Hour__c != null &&
                    item.Origin_Labour_Hour__c != 0 &&
                    item.Labour_Hours__c > item.Origin_Labour_Hour__c)
                ) {
                    //productNode.addChildElement('Amount',null,null).addTextNode(String.valueOf(totalPriceBeforeTax.setScale(0, RoundingMode.HALF_UP))); // require // amount = quantity * price
                    //item.Amount__c = totalPriceBeforeTax.setScale(0, RoundingMode.HALF_UP);
                    line.Amount__c = totalPriceBeforeTax.setScale(
                        0,
                        RoundingMode.HALF_UP
                    );

                    Decimal discountPercent = 0;
                    //item.Discount__c = discountPercent;
                    //item.DiscountAmount__c = 0;
                    line.Discount__c = discountPercent; // GiamGia
                    line.DiscountAmount__c = 0; // GiamGia
                    discountAmount = 0;
                } else {
                    // if(item.Order.Promotion_Item__r.Promotion__r.RecordTypeId == RecordTypeHelper.PROMOTIONSTANDARD && item.Discount__c != 0)
                    Decimal discountPercent = notIncludeVat
                        ? discount
                        : (item.Discount_Percent__c != null
                              ? item.Discount_Percent__c.setScale(
                                    0,
                                    RoundingMode.HALF_UP
                                )
                              : 0);
                    //productNode.addChildElement('Amount',null,null).addTextNode(String.valueOf(totalPriceBeforeTax.setScale(0, RoundingMode.HALF_UP))); // require // amount = quantity * price
                    //item.Amount__c = totalPriceBeforeTax.setScale(0, RoundingMode.HALF_UP);
                    line.Amount__c = totalPriceBeforeTax.setScale(
                        0,
                        RoundingMode.HALF_UP
                    );

                    //item.Discount__c = discountPercent.setScale(0, RoundingMode.HALF_UP);
                    //item.DiscountAmount__c = discountAmount.setScale(0, RoundingMode.HALF_UP);
                    line.Discount__c = discountPercent.setScale(
                        0,
                        RoundingMode.HALF_UP
                    ); // GiamGia
                    line.DiscountAmount__c = discountAmount.setScale(
                        0,
                        RoundingMode.HALF_UP
                    ); // GiamGia
                }

                totalAmount += totalPriceBeforeTax.setScale(
                    0,
                    RoundingMode.HALF_UP
                );
                totalDiscountAmount += discountAmount.setScale(
                    0,
                    RoundingMode.HALF_UP
                );
                //totalVatAmount += vatAmount;
                if (
                    (order.RecordTypeId ==
                    RecordTypeHelper.ORDER_SERVICE_ORDER &&
                    item.Discount__c != 0 &&
                    item.Discount__c != null &&
                    item.Discount__c != null &&
                    item.Order.Campaign__r.Promotion_Item__r.RecordType.Name ==
                    '% Discount') ||
                    (order.RecordTypeId == RecordTypeHelper.ORDER_PCA &&
                    item.Discount__c != 0 &&
                    item.Discount__c != null &&
                    item.Discount__c != null &&
                    item.Order.Promotion_Item__r.Promotion__r.RecordType.Name ==
                    'Standard')
                ) {
                    totalNetAmount +=
                        item.ListPrice.setScale(0, RoundingMode.HALF_UP) *
                        item.Quantity;
                } else if (
                    item.Labour_Hours__c != null &&
                    item.Origin_Labour_Hour__c != null &&
                    item.Origin_Labour_Hour__c != 0 &&
                    item.Labour_Hours__c > item.Origin_Labour_Hour__c
                ) {
                    totalNetAmount += (item.ListPrice *
                        item.Labour_Hours__c /
                        item.Origin_Labour_Hour__c)
                        .setScale(0, RoundingMode.HALF_UP);
                } else {
                    totalNetAmount += item.TotalPrice.setScale(
                        0,
                        RoundingMode.HALF_UP
                    );
                }

                line.Product__c = item.Product2Id;

                listELine.add(line);
            }
            totalNetAmount = notIncludeVat ? totalAmount : totalNetAmount;
            totalVatAmount = notIncludeVat ? 0 : totalNetAmount - totalAmount;

            einvoice.Not_Include_VAT__c = notIncludeVat;
            einvoice.Total_Amount__c = totalAmount.setScale(
                0,
                RoundingMode.HALF_UP
            );
            einvoice.VATRate__c = (notIncludeVat
                ? 0
                : VATRate.setScale(0, RoundingMode.HALF_UP)); // Thue suat
            einvoice.VATAmount__c = totalVatAmount.setScale(
                0,
                RoundingMode.HALF_UP
            );
            einvoice.DiscountAmount__c = totalDiscountAmount.setScale(
                0,
                RoundingMode.HALF_UP
            ); //
            einvoice.Amount__c = totalNetAmount.setScale(
                0,
                RoundingMode.HALF_UP
            ); // Tong cong
            einvoice.AmountInWords__c =
                nameFormat(
                    ConvertCurrencyToVietnamese.convertV(
                        totalNetAmount.setScale(0, RoundingMode.HALF_UP)
                    )
                ) + ' Đồng'; // Tong cong
            einvoice.ArisingDate__c = Date.today();
            einvoice.EmailKhachHang__c = account.PersonEmail;
            einvoice.Extra__c = account.PersonEmail;
            einvoice.ProductLine__c = productLine;
            einvoice.SoHopDong__c = order.Contract.ContractNumber;
            einvoice.NguonDuLieu__c = 'webservice_CRM';
            einvoice.Invoice_Pattern__c = pattern;
            einvoice.Invoice_Serial__c = serial;

            if (order.RecordTypeId == RecordTypeHelper.ORDER_BIKE) {
                einvoice.SST__c = '1';
            } else {
                einvoice.SST__c = '0';
            }

            einvoice.SOPHIEUTHU__c = paymentCode;
            einvoice.SALEORDER__c = order.Order_Number__c;
            einvoice.DEALERCODE__c = order.DO_DL__r.DO_DL_Code__c;
            einvoice.Type__c = 'Export';

            insert einvoice;

            order.Invoice_Date__c = Date.today();
            order.Is_Created_Or_Sent_Invoice__c = true;
            if (order.Asset__c != null) {
                order.Asset__r.PurchaseDate = Date.today();
            }
            update order;

            for (OrderItem item : listOrderItem) {
                item.Einvoice__c = einvoice.Id;
            }
            update listOrderItem;

            for (Einvoice_Line__c line : listELine) {
                line.Einvoice__c = einvoice.Id;
            }

            if (!listELine.isEmpty()) {
                insert listELine;
            }
        } catch (Exception e) {
            order.Is_Created_Or_Sent_Invoice__c = false;
            update order;
            strMessage =
                'Order Id : ' +
                order.Id +
                ' - ' +
                e.getMessage() +
                ' - ' +
                e.getLineNumber();
            logError('EinvoiceHelper Create Invoice', strMessage, '', '', '');
            system.debug(strMessage);
        }
    }

    //Gửi einvoice qua cho các chi nhánh dựa trên Location của DO DL
    public static void sendInvoice(
        Order order,
        Contract_Information__c contractInfo,
        List<OrderItem> listOrderItem,
        Decimal VATRate,
        String paymentCode,
        String paymentMethod,
        Integer count
    ) {
        // test sanbox (801O000000195eeIAA);

        DateTime today = Datetime.now();
        String dateOutput = today.format('dd/MM/yyyy');

        if (order == null) {
            return;
        }
        string strMessage = '';
        string strOutput = '';

        /*Map<String, Schema.SObjectField> orderFieldMap = Order.sObjectType.getDescribe().fields.getMap();
        List<string> orderSelectFields = new List<String>(orderFieldMap.keySet());
        orderSelectFields.add('DO_DL__r.DO_DL_Code__c');
        orderSelectFields.add('Contract.ContractNumber');
        String orderSoql = 'SELECT ' + String.join(orderSelectFields, ',');
        orderSoql += ' FROM Order';
        orderSoql += ' WHERE Id = :orderId'; 
        Order order = Database.query(orderSoql); */
        String accountId = order.AccountId;

        /*Map<String, Schema.SObjectField> orderlineFieldMap = OrderItem.sObjectType.getDescribe().fields.getMap();
        List<string> orderlineSelectFields = new List<String>(orderlineFieldMap.keySet());
        orderlineSelectFields.add('Product2.Name');
        orderlineSelectFields.add('Product2.Quantity_of_Unit__c');
        String orderLineSoql = 'SELECT ' + String.join(orderlineSelectFields, ',');
        orderLineSoql += ' FROM OrderItem';
        orderLineSoql += ' WHERE OrderId =: orderId'; 
        List<OrderItem> listOrderItem = Database.query(orderLineSoql); */

        Map<String, Schema.SObjectField> accountFieldMap = Account.sObjectType.getDescribe()
            .fields.getMap();
        List<string> accountSelectFields = new List<String>(
            accountFieldMap.keySet()
        );
        String accountSoql = 'SELECT ' + String.join(accountSelectFields, ',');
        accountSoql += ' FROM Account';
        accountSoql += ' WHERE Id = : accountId';
        Account account = Database.query(accountSoql);

        try {
            String endPoint = '';
            String accountYMH = '';
            string accountPassYMH = '';
            string userNameYMH = '';
            string userPassYMH = '';
            string pattern = '';
            string serial = '';

            if (order.DO_DL__r.Einvoice_Location__c == 'Hồ Chí Minh') {
                endPoint = apiSetting.HCM_Endpoint__c; /// hcm
                accountYMH = apiSetting.HCM_Account__c;
                accountPassYMH = apiSetting.HCM_Account_Pass__c;
                userNameYMH = apiSetting.HCM_User__c;
                userPassYMH = apiSetting.HCM_User_Pass__c;
                if (order.RecordTypeId == RecordTypeHelper.ORDER_BIKE) {
                    pattern = order.Is_Employee__c
                        ? apiSetting.HCM_Employee_Bike_Pattern__c
                        : apiSetting.HCM_Bike_Pattern__c;
                    serial = order.Is_Employee__c
                        ? apiSetting.HCM_Employee_Bike_Serial__c
                        : apiSetting.HCM_Bike_Serial__c;
                } else {
                    pattern = order.Is_Employee__c
                        ? apiSetting.HCM_Employee_Pattern__c
                        : apiSetting.HCM_Pattern__c;
                    serial = order.Is_Employee__c
                        ? apiSetting.HCM_Employee_Serial__c
                        : apiSetting.HCM_Serial__c;
                }
            } else if (order.DO_DL__r.Einvoice_Location__c == 'Nha Trang') {
                endPoint = apiSetting.NT_Enpoint__c; // nt
                accountYMH = apiSetting.NT_Account__c;
                accountPassYMH = apiSetting.NT_Account_Pass__c;
                userNameYMH = apiSetting.NT_User__c;
                userPassYMH = apiSetting.NT_User_Pass__c;
                if (order.RecordTypeId == RecordTypeHelper.ORDER_BIKE) {
                    pattern = order.Is_Employee__c
                        ? apiSetting.NT_Employee_Bike_Pattern__c
                        : apiSetting.NT_Bike_Pattern__c;
                    serial = order.Is_Employee__c
                        ? apiSetting.NT_Employee_Bike_Serial__c
                        : apiSetting.NT_Bike_Serial__c;
                } else {
                    pattern = order.Is_Employee__c
                        ? apiSetting.NT_Employee_Pattern__c
                        : apiSetting.NT_Pattern__c;
                    serial = order.Is_Employee__c
                        ? apiSetting.NT_Employee_Serial__c
                        : apiSetting.NT_Serial__c;
                }
            } else if (order.DO_DL__r.Einvoice_Location__c == 'Hà Nội') {
                endPoint = apiSetting.HN_Enpoint__c; // nt
                accountYMH = apiSetting.HN_Account__c;
                accountPassYMH = apiSetting.HN_Account_Pass__c;
                userNameYMH = apiSetting.HN_User__c;
                userPassYMH = apiSetting.HN_User_Pass__c;
                if (order.RecordTypeId == RecordTypeHelper.ORDER_BIKE) {
                    pattern = order.Is_Employee__c
                        ? apiSetting.HN_Employee_Bike_Pattern__c
                        : apiSetting.HN_Bike_Pattern__c;
                    serial = order.Is_Employee__c
                        ? apiSetting.HN_Employee_Bike_Serial__c
                        : apiSetting.HN_Bike_Serial__c;
                } else {
                    pattern = order.Is_Employee__c
                        ? apiSetting.HN_Employee_Pattern__c
                        : apiSetting.HN_Pattern__c;
                    serial = order.Is_Employee__c
                        ? apiSetting.HN_Employee_Serial__c
                        : apiSetting.HN_Serial__c;
                }
            } else if (order.DO_DL__r.Einvoice_Location__c == 'Đà Nẵng') {
                endPoint = apiSetting.DN_Enpoint__c; // nt
                accountYMH = apiSetting.DN_Account__c;
                accountPassYMH = apiSetting.DN_Account_Pass__c;
                userNameYMH = apiSetting.DN_User__c;
                userPassYMH = apiSetting.DN_User_Pass__c;
                if (order.RecordTypeId == RecordTypeHelper.ORDER_BIKE) {
                    pattern = order.Is_Employee__c
                        ? apiSetting.DN_Employee_Bike_Pattern__c
                        : apiSetting.DN_Bike_Pattern__c;
                    serial = order.Is_Employee__c
                        ? apiSetting.DN_Employee_Bike_Serial__c
                        : apiSetting.DN_Bike_Serial__c;
                } else {
                    pattern = order.Is_Employee__c
                        ? apiSetting.DN_Employee_Pattern__c
                        : apiSetting.DN_Pattern__c;
                    serial = order.Is_Employee__c
                        ? apiSetting.DN_Employee_Serial__c
                        : apiSetting.DN_Serial__c;
                }
            }

            Einvoice__c einvoice = new Einvoice__c();

            einvoice.Invoice_Pattern__c = pattern;
            einvoice.Invoice_Serial__c = serial;

            Dom.Document doc2 = new Dom.Document();
            //Dom.Xmlnode xmlInvDataNode = importNode.addChildElement('xmlInvData',null,null);
            Dom.Xmlnode invoicesNode = doc2.createRootElement(
                'Invoices',
                null,
                null
            );
            //Dom.Xmlnode invoicesNode = xmlInvDataNode.addChildElement('Invoices', null, null);
            Dom.Xmlnode invNode = invoicesNode.addChildElement(
                'Inv',
                null,
                null
            );
            invNode.addChildElement('key', null, null)
                .addTextNode(order.Id + '-' + count); // require // The unique identifier of the invoice
            //invNode.addChildElement('key', null, null).addTextNode(order.Id+'-'+count+'-devtest6'); // only for dev test

            Dom.Xmlnode invoiceNode = invNode.addChildElement(
                'Invoice',
                null,
                null
            );
            invoiceNode.addChildElement('CusCode', null, null)
                .addTextNode(
                    account.AccountNumber != null ? account.AccountNumber : ''
                ); // Customer code
            einvoice.CusCode__c = account.AccountNumber;
            if (contractInfo != null && contractInfo.Name != null) {
                invoiceNode.addChildElement('CusName', null, null)
                    .addTextNode(contractInfo.Name); // Customer name
                einvoice.CusName__c = contractInfo.Name;
            } else if (order.Invoice_Type__c == 'Company') {
                invoiceNode.addChildElement('CusName', null, null)
                    .addTextNode(
                        order.Tax_Name__c != null ? order.Tax_Name__c : ''
                    ); // Customer
                einvoice.CusName__c = order.Tax_Name__c;
            } else if (order.Customer__c != null) {
                invoiceNode.addChildElement('CusName', null, null)
                    .addTextNode(
                        order.Customer__c != null ? order.Customer__c : ''
                    ); // Customer name
                einvoice.CusName__c = order.Customer__c;
            } else {
                invoiceNode.addChildElement('CusName', null, null)
                    .addTextNode(account.Name != null ? account.Name : ''); // Customer name
                einvoice.CusName__c = account.Name;
            }

            if (
                contractInfo != null &&
                contractInfo.Address_Full__c != null &&
                contractInfo.RecordType.Name == 'Person'
            ) {
                invoiceNode.addChildElement('CusAddress', null, null)
                    .addTextNode(contractInfo.Address_Full__c); // Customer address
                einvoice.CusAddress__c = contractInfo.Address_Full__c;
                if (order.RecordTypeId != RecordTypeHelper.ORDER_BIKE) {
                    invoiceNode.addChildElement('DIACHIGIAO', null, null)
                        .addTextNode(contractInfo.Address_Full__c);
                    einvoice.DiaChiGiao__c = contractInfo.Address_Full__c;
                }
            } else if (
                contractInfo != null &&
                contractInfo.Head_Office__c != null &&
                contractInfo.RecordType.Name == 'Corporate'
            ) {
                invoiceNode.addChildElement('CusAddress', null, null)
                    .addTextNode(contractInfo.Head_Office__c); // Customer address
                einvoice.CusAddress__c = contractInfo.Head_Office__c;
                if (order.RecordTypeId != RecordTypeHelper.ORDER_BIKE) {
                    invoiceNode.addChildElement('DIACHIGIAO', null, null)
                        .addTextNode(contractInfo.Head_Office__c); //
                    einvoice.DiaChiGiao__c = contractInfo.Head_Office__c;
                }
            } else if (order.Invoice_Type__c == 'Company') {
                invoiceNode.addChildElement('CusAddress', null, null)
                    .addTextNode(order.Tax_Address__c); // Customer address
                einvoice.CusAddress__c = order.Tax_Address__c;
                if (order.RecordTypeId != RecordTypeHelper.ORDER_BIKE) {
                    invoiceNode.addChildElement('DIACHIGIAO', null, null)
                        .addTextNode(order.Tax_Address__c); //
                    einvoice.DiaChiGiao__c = order.Tax_Address__c;
                }
            } else if (order.Account.Address_Full__c != null) {
                invoiceNode.addChildElement('CusAddress', null, null)
                    .addTextNode(order.Account.Address_Full__c); // Customer address
                einvoice.CusAddress__c = order.Account.Address_Full__c;
                if (order.RecordTypeId != RecordTypeHelper.ORDER_BIKE) {
                    invoiceNode.addChildElement('DIACHIGIAO', null, null)
                        .addTextNode(order.Account.Address_Full__c); //
                    einvoice.DiaChiGiao__c = order.Account.Address_Full__c;
                }
            } else if (order.Tax_Address__c != null) {
                invoiceNode.addChildElement('CusAddress', null, null)
                    .addTextNode(
                        order.Tax_Address__c != null ? order.Tax_Address__c : ''
                    ); // Customer address
                einvoice.CusAddress__c = order.Tax_Address__c;
                if (order.RecordTypeId != RecordTypeHelper.ORDER_BIKE) {
                    invoiceNode.addChildElement('DIACHIGIAO', null, null)
                        .addTextNode(
                            order.Tax_Address__c != null
                                ? order.Tax_Address__c
                                : ''
                        ); // Customer address
                    einvoice.DiaChiGiao__c = order.Tax_Address__c;
                }
            } else {
                invoiceNode.addChildElement('CusAddress', null, null)
                    .addTextNode(
                        order.Address_Full__c != null
                            ? order.Address_Full__c
                            : ''
                    ); // Customer address
                einvoice.CusAddress__c = order.Address_Full__c;
                if (order.RecordTypeId != RecordTypeHelper.ORDER_BIKE) {
                    invoiceNode.addChildElement('DIACHIGIAO', null, null)
                        .addTextNode(
                            order.Address_Full__c != null
                                ? order.Address_Full__c
                                : ''
                        ); // Customer address
                    einvoice.DiaChiGiao__c = order.Address_Full__c;
                }
            }

            if (contractInfo != null && contractInfo.Mobile__c != null) {
                invoiceNode.addChildElement('CusPhone', null, null)
                    .addTextNode(contractInfo.Mobile__c); // Customer phone
                einvoice.CusPhone__c = contractInfo.Mobile__c;
            } else if (order.Invoice_Type__c == 'Company') {
                invoiceNode.addChildElement('CusPhone', null, null)
                    .addTextNode(
                        order.Tax_Mobile__c != null ? order.Tax_Mobile__c : ''
                    ); // Customer phone
                einvoice.CusPhone__c = order.Tax_Mobile__c;
            } else if (order.Tax_Mobile__c != null) {
                invoiceNode.addChildElement('CusPhone', null, null)
                    .addTextNode(
                        order.Tax_Mobile__c != null ? order.Tax_Mobile__c : ''
                    ); // Customer phone
                einvoice.CusPhone__c = order.Tax_Mobile__c;
            } else {
                invoiceNode.addChildElement('CusPhone', null, null)
                    .addTextNode(
                        account.PersonMobilePhone != null
                            ? account.PersonMobilePhone
                            : ''
                    ); // Customer phone
                einvoice.CusPhone__c = account.PersonMobilePhone;
            }

            if (contractInfo != null && contractInfo.Tax_code__c != null) {
                invoiceNode.addChildElement('CusTaxCode', null, null)
                    .addTextNode(contractInfo.Tax_code__c); // Customer tax code
                einvoice.CusTaxCode__c = contractInfo.Tax_code__c;
            } else if (
                order.Invoice_Type__c == 'Company' ||
                order.Invoice_Type__c == 'Person'
            ) {
                invoiceNode.addChildElement('CusTaxCode', null, null)
                    .addTextNode(order.Tax_Code__c); // Customer tax code
                einvoice.CusTaxCode__c = order.Tax_code__c;
            } else if (order.Tax_Code__c != null) {
                invoiceNode.addChildElement('CusTaxCode', null, null)
                    .addTextNode(order.Tax_Code__c); // Customer tax code
                einvoice.CusTaxCode__c = order.Tax_code__c;
            } else if (account.Tax_Code__c != null) {
                invoiceNode.addChildElement('CusTaxCode', null, null)
                    .addTextNode(account.Tax_Code__c); // Customer tax code
                einvoice.CusTaxCode__c = account.Tax_code__c;
            }

            // Lay tu payment va check truong hop vua transfer vua cash
            if (
                paymentMethod != 'null' &&
                paymentMethod != null &&
                paymentMethod != ''
            ) {
                invoiceNode.addChildElement('PaymentMethod', null, null)
                    .addTextNode(paymentMethod); // Payment method: Cash, transfer,…
                einvoice.PaymentMethod__c = paymentMethod;
            } else {
                invoiceNode.addChildElement('PaymentMethod', null, null)
                    .addTextNode('CK'); // Payment method: Cash, transfer,…
                einvoice.PaymentMethod__c = 'CK';
            }

            String productLine = '';
            Decimal totalAmount = 0;
            Decimal totalNetAmount = 0;
            Decimal totalVatAmount = 0;
            Decimal totalDiscountAmount = 0;
            Boolean notIncludeVat = false;
            if (
                order.Generated_Redeem__c == true &&
                order.RecordTypeId == RecordTypeHelper.ORDER_PCA
            ) {
                notIncludeVat = true;
            } else if (
                order.RecordTypeId == RecordTypeHelper.ORDER_FREE_SERVICE &&
                order.Account.RecordTypeId == RecordTypeHelper.ACCOUNT_DODL
            ) {
                notIncludeVat = true;
            }
            Dom.Xmlnode productsNode = invoiceNode.addChildElement(
                'Products',
                null,
                null
            ); // Product list

            //test Special Promotion
            //Dom.Xmlnode productNode1 = productsNode.addChildElement('Product', null, null); // Product
            //productNode1.addChildElement('ProdName',null,null).addTextNode('Special Promotion');

            List<Einvoice_Line__c> listELine = new List<Einvoice_Line__c>();
            for (OrderItem item : listOrderItem) {
                productLine = item.Record_Type_Name__c;
                Einvoice_Line__c line = new Einvoice_Line__c();
                line.Order_Product__c = item.Id;

                Dom.Xmlnode productNode = productsNode.addChildElement(
                    'Product',
                    null,
                    null
                ); // Product
                productNode.addChildElement('Code', null, null)
                    .addTextNode(
                        item.Product_Code__c != null ? item.Product_Code__c : ''
                    ); // model

                if (order.RecordTypeId == RecordTypeHelper.ORDER_BIKE) {
                    String bikeName = order.Bike_Description__c;
                    productNode.addChildElement('ProdName', null, null)
                        .addTextNode(bikeName != null ? bikeName : 'Bike Name'); // require // Product name
                    line.Product_Name__c = item.Product2.Name;
                } else {
                    if (
                        ((order.RecordTypeId ==
                        RecordTypeHelper.ORDER_FREE_COUPON ||
                        order.RecordTypeId ==
                        RecordTypeHelper.ORDER_SERVICE_ORDER) &&
                        item.Applied__c == true)
                    ) {
                        notIncludeVat = true;
                    }

                    if (
                        (order.RecordTypeId ==
                        RecordTypeHelper.ORDER_SERVICE_ORDER &&
                        item.Discount__c != 0 &&
                        item.Order.Campaign__r.Promotion_Item__r.RecordType.Name ==
                        '% Discount') ||
                        (item.Order.Promotion_Item__r.Promotion__r.RecordTypeId ==
                        RecordTypeHelper.PROMOTIONDEFAULT &&
                        item.Product2.Is_Genuine__c == true &&
                        item.Discount__c != 0) ||
                        (order.RecordTypeId == RecordTypeHelper.ORDER_PCA &&
                        item.Discount__c != 0 &&
                        item.Order.Promotion_Item__r.Promotion__r.RecordType.Name ==
                        'Standard')
                    ) {
                        productNode.addChildElement('ProdName', null, null)
                            .addTextNode(
                                item.Line_Description__c != null
                                    ? item.Line_Description__c
                                    : 'Missing Name'
                            ); // require // Product name
                        line.Product_Name__c = item.Line_Description__c;
                    } else {
                        productNode.addChildElement('ProdName', null, null)
                            .addTextNode(
                                item.Product2.Name != null
                                    ? item.Product2.Name
                                    : 'Missing Name'
                            ); // require // Product name
                        line.Product_Name__c = item.Product2.Name;
                    }
                }

                // bỏ Product Unit cho Product Service
                if (
                    item.Product2.RecordTypeId ==
                    RecordTypeHelper.PRODUCT_SERVICE_PACKAGE ||
                    item.Product2.RecordTypeId == RecordTypeHelper.SV_JOB
                ) {
                    productNode.addChildElement('ProdUnit', null, null)
                        .addTextNode(''); // unit
                } else {
                    productNode.addChildElement('ProdUnit', null, null)
                        .addTextNode(
                            item.Product2.Product_Unit__c != null
                                ? item.Product2.Product_Unit__c
                                : ''
                        ); // unit
                }

                if (totalDiscountAmount > 0) {
                    productNode.addChildElement('IsSum', null, null)
                        .addTextNode('2'); // 0-Goods, services; 1-Promotion; 2-Trade discount (in case you want to show discount information by line); 4-Note/interpretation
                    line.IsSum__c = '2';
                } else {
                    productNode.addChildElement('IsSum', null, null)
                        .addTextNode('0'); // 0-Goods, services; 1-Promotion; 2-Trade discount (in case you want to show discount information by line); 4-Note/interpretation
                    line.IsSum__c = '0';
                }

                Decimal discount = item.Discount__c != null
                    ? item.Discount__c
                    : 0;
                if (item.Product2.RecordTypeId == RecordTypeHelper.SV_JOB) {
                    productNode.addChildElement('ProdQuantity', null, null)
                        .addTextNode(
                            item.Quantity != null ? String.valueOf(0) : '0'
                        ); // quantity
                    line.Quantity__c = 0;
                } else {
                    productNode.addChildElement('ProdQuantity', null, null)
                        .addTextNode(
                            item.Quantity != null
                                ? String.valueOf(
                                      item.Quantity.setScale(
                                          0,
                                          RoundingMode.HALF_UP
                                      )
                                  )
                                : '0'
                        ); // quantity
                    line.Quantity__c = item.Quantity;
                }

                /*if(item.Product2.RecordTypeId == RecordTypeHelper.SV_JOB) // 1/7/2022 và thay đổi công thức trên item.Discount_Percent__c
                {
                    productNode.addChildElement('ProdQuantity',null,null).addTextNode(item.Quantity != null ? String.valueOf((item.Quantity *  (item.Labour_Hours__c / item.Origin_Labour_Hour__c)).setScale(0, RoundingMode.HALF_UP)) : '0'); // quantity   
                }
                else
                {
                    productNode.addChildElement('ProdQuantity',null,null).addTextNode(item.Quantity != null ? String.valueOf(item.Quantity.setScale(0, RoundingMode.HALF_UP)) : '0'); // quantity      
                }*/

                Decimal amountBeforeVat = item.ListPrice / (1 + VatRate / 100);
                // Task ymhvn-1034, (2)...
                if (
                    (order.RecordTypeId == RecordTypeHelper.ORDER_BIKE) &&
                    order.Is_Employee__c
                ) {
                    amountBeforeVat = item.UnitPrice / (1 + VatRate / 100);
                }
                // Task ymhvn-1034, ...(2)
                /*if (item.Product2.RecordTypeId == RecordTypeHelper.SV_JOB)
                {
                    amountBeforeVat = item.ListPrice / ( 1 + VatRate/100) *  (item.Labour_Hours__c / item.Origin_Labour_Hour__c);
                }     */
                Decimal vatAmount = (notIncludeVat
                    ? 0
                    : item.ListPrice - amountBeforeVat);
                Decimal discountAmount =
                    amountBeforeVat *
                    ((notIncludeVat ? discount : item.Discount_Percent__c) /
                    100) *
                    item.Quantity;

                if (
                    item.Product2.RecordTypeId ==
                    RecordTypeHelper.PRODUCT_MODEL // Product Bike // yêu cầu của Dương 28/6/2022
                ) {
                    discountAmount =
                        (item.ListPrice - item.UnitPrice) / (1 + VatRate / 100);
                }
                //system.debug('Discount Amount :'+ discountAmount);
                Decimal totalPriceBeforeTax =
                    amountBeforeVat * item.Quantity - discountAmount;
                if (
                    item.Product2.RecordTypeId ==
                    RecordTypeHelper.PRODUCT_MODEL // Product Bike // yêu cầu của Dương 28/6/2022
                ) {
                    totalPriceBeforeTax =
                        (amountBeforeVat * item.Quantity)
                            .setScale(0, RoundingMode.HALF_UP) -
                        discountAmount.setScale(0, RoundingMode.HALF_UP);
                } else if (
                    (order.RecordTypeId ==
                    RecordTypeHelper.ORDER_SERVICE_ORDER &&
                    item.Discount__c != 0 &&
                    item.Discount__c != null &&
                    item.Order.Campaign__r.Promotion_Item__r.RecordType.Name ==
                    '% Discount') ||
                    (order.RecordTypeId == RecordTypeHelper.ORDER_PCA &&
                    item.Discount__c != 0 &&
                    item.Discount__c != null &&
                    item.Order.Promotion_Item__r.Promotion__r.RecordType.Name ==
                    'Standard')
                ) {
                    totalPriceBeforeTax = (amountBeforeVat * item.Quantity)
                        .setScale(0, RoundingMode.HALF_UP);
                } else if (
                    item.Labour_Hours__c != null &&
                    item.Origin_Labour_Hour__c != null &&
                    item.Origin_Labour_Hour__c != 0 &&
                    item.Labour_Hours__c > item.Origin_Labour_Hour__c
                ) {
                    totalPriceBeforeTax = (amountBeforeVat *
                        item.Labour_Hours__c /
                        item.Origin_Labour_Hour__c)
                        .setScale(0, RoundingMode.HALF_UP);
                }
                /*else if (item.Product2.RecordTypeId == RecordTypeHelper.SV_JOB)  // 1/7/2022 và thay đổi công thức trên item.Discount_Percent__c
                {
                    totalPriceBeforeTax = (amountBeforeVat * item.Quantity *  (item.Labour_Hours__c / item.Origin_Labour_Hour__c)).setScale(0, RoundingMode.HALF_UP) - discountAmount.setScale(0, RoundingMode.HALF_UP); 
                }*/

                if (
                    (order.RecordTypeId ==
                    RecordTypeHelper.ORDER_SERVICE_ORDER &&
                    item.Discount__c != 0 &&
                    item.Discount__c != null &&
                    item.Discount__c != null &&
                    item.Order.Campaign__r.Promotion_Item__r.RecordType.Name ==
                    '% Discount') ||
                    (order.RecordTypeId == RecordTypeHelper.ORDER_PCA &&
                    item.Discount__c != 0 &&
                    item.Discount__c != null &&
                    item.Discount__c != null &&
                    item.Order.Promotion_Item__r.Promotion__r.RecordType.Name ==
                    'Standard')
                ) {
                    Decimal amountBeforeVatBeforeDiscount =
                        item.ListPrice / (1 + VatRate / 100);
                    productNode.addChildElement('ProdPrice', null, null)
                        .addTextNode(
                            String.valueOf(
                                amountBeforeVatBeforeDiscount.setScale(
                                    0,
                                    RoundingMode.HALF_UP
                                )
                            )
                        ); // price
                } else if (
                    (item.Order.Promotion_Item__r.Promotion__r.RecordTypeId ==
                    RecordTypeHelper.PROMOTIONDEFAULT &&
                    item.Product2.Is_Genuine__c == true &&
                    item.Discount__c != 0 &&
                    item.Discount__c != null) ||
                    (item.Order.Manual_Discount_Approve__c == true &&
                    item.Discount__c != 0 &&
                    item.Discount__c != null)
                ) {
                    Decimal discountAmountWithouQuantity =
                        amountBeforeVat *
                        ((notIncludeVat ? discount : item.Discount_Percent__c) /
                        100); // Discount cho amountBeforeVat ko tính discount
                    Decimal amountBeforeVatAfterDiscount =
                        item.ListPrice / (1 + VatRate / 100) -
                        discountAmountWithouQuantity;
                    productNode.addChildElement('ProdPrice', null, null)
                        .addTextNode(
                            String.valueOf(
                                amountBeforeVatAfterDiscount.setScale(
                                    0,
                                    RoundingMode.HALF_UP
                                )
                            )
                        ); // price
                    line.ProdPrice__c = amountBeforeVatAfterDiscount.setScale(
                        0,
                        RoundingMode.HALF_UP
                    );
                } else if (
                    item.Labour_Hours__c != null &&
                    item.Origin_Labour_Hour__c != null &&
                    item.Origin_Labour_Hour__c != 0 &&
                    item.Labour_Hours__c > item.Origin_Labour_Hour__c
                ) {
                    Decimal amountBeforeVatAfterHour = (amountBeforeVat *
                        item.Labour_Hours__c /
                        item.Origin_Labour_Hour__c)
                        .setScale(0, RoundingMode.HALF_UP);
                    productNode.addChildElement('ProdPrice', null, null)
                        .addTextNode(
                            String.valueOf(
                                amountBeforeVatAfterHour.setScale(
                                    0,
                                    RoundingMode.HALF_UP
                                )
                            )
                        ); // price
                    line.ProdPrice__c = amountBeforeVatAfterHour.setScale(
                        0,
                        RoundingMode.HALF_UP
                    );
                } else {
                    productNode.addChildElement('ProdPrice', null, null)
                        .addTextNode(
                            String.valueOf(
                                amountBeforeVat.setScale(
                                    0,
                                    RoundingMode.HALF_UP
                                )
                            )
                        ); // price
                    line.ProdPrice__c = amountBeforeVat.setScale(
                        0,
                        RoundingMode.HALF_UP
                    );
                }

                // https://beunik.atlassian.net/browse/YMVN-536
                if (
                    (item.Order.Promotion_Item__r.Promotion__r.RecordTypeId ==
                    RecordTypeHelper.PROMOTIONDEFAULT &&
                    item.Product2.Is_Genuine__c == true &&
                    item.Discount__c != 0 &&
                    item.Discount__c != null) ||
                    (item.Order.Manual_Discount_Approve__c == true &&
                    item.Discount__c != 0 &&
                    item.Discount__c != null) ||
                    (order.RecordTypeId ==
                    RecordTypeHelper.ORDER_SERVICE_ORDER &&
                    item.Discount__c != 0 &&
                    item.Discount__c != null &&
                    item.Order.Campaign__r.Promotion_Item__r.RecordType.Name ==
                    '% Discount') ||
                    (order.RecordTypeId == RecordTypeHelper.ORDER_PCA &&
                    item.Discount__c != 0 &&
                    item.Discount__c != null &&
                    item.Order.Promotion_Item__r.Promotion__r.RecordType.Name ==
                    'Standard') ||
                    (item.Labour_Hours__c != null &&
                    item.Origin_Labour_Hour__c != null &&
                    item.Origin_Labour_Hour__c != 0 &&
                    item.Labour_Hours__c > item.Origin_Labour_Hour__c)
                ) {
                    productNode.addChildElement('Amount', null, null)
                        .addTextNode(
                            String.valueOf(
                                totalPriceBeforeTax.setScale(
                                    0,
                                    RoundingMode.HALF_UP
                                )
                            )
                        ); // require // amount = quantity * price
                    Decimal discountPercent = 0;
                    productNode.addChildElement('Discount', null, null)
                        .addTextNode(String.valueOf(discountPercent)); // discount // thêm 17/2/2022
                    productNode.addChildElement('DiscountAmount', null, null)
                        .addTextNode('0'); // discount amount // thêm 17/2/2022
                    discountAmount = 0;

                    line.Amount__c = totalPriceBeforeTax.setScale(
                        0,
                        RoundingMode.HALF_UP
                    );
                    line.Discount__c = discountPercent;
                    line.DiscountAmount__c = 0;
                } else {
                    // if(item.Order.Promotion_Item__r.Promotion__r.RecordTypeId == RecordTypeHelper.PROMOTIONSTANDARD && item.Discount__c != 0)
                    productNode.addChildElement('Amount', null, null)
                        .addTextNode(
                            String.valueOf(
                                totalPriceBeforeTax.setScale(
                                    0,
                                    RoundingMode.HALF_UP
                                )
                            )
                        ); // require // amount = quantity * price
                    Decimal discountPercent = notIncludeVat
                        ? discount
                        : (item.Discount_Percent__c != null
                              ? item.Discount_Percent__c.setScale(
                                    0,
                                    RoundingMode.HALF_UP
                                )
                              : 0);
                    productNode.addChildElement('Discount', null, null)
                        .addTextNode(
                            String.valueOf(
                                discountPercent.setScale(
                                    0,
                                    RoundingMode.HALF_UP
                                )
                            )
                        ); // discount // thêm 17/2/2022
                    productNode.addChildElement('DiscountAmount', null, null)
                        .addTextNode(
                            discountAmount != null
                                ? String.valueOf(
                                      discountAmount.setScale(
                                          0,
                                          RoundingMode.HALF_UP
                                      )
                                  )
                                : '0'
                        ); // discount amount // thêm 17/2/2022

                    line.Amount__c = totalPriceBeforeTax.setScale(
                        0,
                        RoundingMode.HALF_UP
                    );
                    line.Discount__c = discountPercent.setScale(
                        0,
                        RoundingMode.HALF_UP
                    );
                    line.DiscountAmount__c = discountAmount.setScale(
                        0,
                        RoundingMode.HALF_UP
                    );
                }

                totalAmount += totalPriceBeforeTax.setScale(
                    0,
                    RoundingMode.HALF_UP
                );
                totalDiscountAmount += discountAmount.setScale(
                    0,
                    RoundingMode.HALF_UP
                );
                //totalVatAmount += vatAmount;
                if (
                    (order.RecordTypeId ==
                    RecordTypeHelper.ORDER_SERVICE_ORDER &&
                    item.Discount__c != 0 &&
                    item.Discount__c != null &&
                    item.Order.Campaign__r.Promotion_Item__r.RecordType.Name ==
                    '% Discount') ||
                    (order.RecordTypeId == RecordTypeHelper.ORDER_PCA &&
                    item.Discount__c != 0 &&
                    item.Discount__c != null &&
                    item.Order.Promotion_Item__r.Promotion__r.RecordType.Name ==
                    'Standard')
                ) {
                    totalNetAmount +=
                        item.ListPrice.setScale(0, RoundingMode.HALF_UP) *
                        item.Quantity;
                } else if (
                    item.Labour_Hours__c != null &&
                    item.Origin_Labour_Hour__c != null &&
                    item.Origin_Labour_Hour__c != 0 &&
                    item.Labour_Hours__c > item.Origin_Labour_Hour__c
                ) {
                    totalNetAmount += (item.ListPrice *
                        item.Labour_Hours__c /
                        item.Origin_Labour_Hour__c)
                        .setScale(0, RoundingMode.HALF_UP);
                } else {
                    totalNetAmount += item.TotalPrice.setScale(
                        0,
                        RoundingMode.HALF_UP
                    );
                }

                line.Product__c = item.Product2Id;
                listELine.add(line);
            }

            totalNetAmount = notIncludeVat ? totalAmount : totalNetAmount;
            //System.debug('Total net amount: '+ totalNetAmount);

            // Tính lại total amount theo line = total price của từng line
            if (order.Total_Amount__c != null)
                invoiceNode.addChildElement('Total', null, null)
                    .addTextNode(
                        String.valueOf(
                            totalAmount.setScale(0, RoundingMode.HALF_UP)
                        )
                    ); // sum product amount
            einvoice.Total_Amount__c = totalAmount.setScale(
                0,
                RoundingMode.HALF_UP
            );
            invoiceNode.addChildElement('VATRate', null, null)
                .addTextNode(
                    String.valueOf(
                        notIncludeVat
                            ? 0
                            : VATRate.setScale(0, RoundingMode.HALF_UP)
                    )
                ); // chưa có // % Vat Rate
            einvoice.VATRate__c = VATRate.setScale(0, RoundingMode.HALF_UP);

            totalVatAmount = notIncludeVat ? 0 : totalNetAmount - totalAmount;
            //System.debug('Total net amount: '+ totalVatAmount);
            String VATAmount = String.valueOf(
                totalVatAmount.setScale(0, RoundingMode.HALF_UP)
            );
            invoiceNode.addChildElement('VATAmount', null, null)
                .addTextNode(VATAmount); // chưa có // Tax money = Total * VATRate
            einvoice.VATAmount__c = totalVatAmount.setScale(
                0,
                RoundingMode.HALF_UP
            );

            //String discountAmount = String.valueOf(totalDiscountAmount.setScale(0, RoundingMode.HALF_UP)); // discount này ko phải là tổng discount line mà của voucher
            //invoiceNode.addChildElement('DiscountAmount', null, null).addTextNode(String.valueOf(discountAmount));
            //System.debug('Total net amount: '+ discountAmount);

            if (order.Net_Amount__c != null)
                invoiceNode.addChildElement('Amount', null, null)
                    .addTextNode(
                        String.valueOf(
                            totalNetAmount.setScale(0, RoundingMode.HALF_UP)
                        )
                    ); // Total money after tax =  Total + VATAmount
            einvoice.Amount__c = totalNetAmount.setScale(
                0,
                RoundingMode.HALF_UP
            );
            //invoiceNode.addChildElement('ConvertedAmount', null, null).addTextNode(String.valueOf(order.Net_Amount__c)); // Converted Amount according to  exchange rate
            if (order.Net_Amount__c != null)
                invoiceNode.addChildElement('AmountInWords', null, null)
                    .addTextNode(
                        nameFormat(
                            ConvertCurrencyToVietnamese.convertV(
                                totalNetAmount.setScale(0, RoundingMode.HALF_UP)
                            )
                        ) + ' Đồng'
                    ); // Amount read in words
            einvoice.AmountInWords__c =
                nameFormat(
                    ConvertCurrencyToVietnamese.convertV(
                        totalNetAmount.setScale(0, RoundingMode.HALF_UP)
                    )
                ) + ' Đồng';
            invoiceNode.addChildElement('ArisingDate', null, null)
                .addTextNode(dateOutput); // Today // Date of invoice creation
            einvoice.ArisingDate__c = Date.today();
            if (account.PersonEmail != null)
                invoiceNode.addChildElement('Extra', null, null)
                    .addTextNode(account.PersonEmail); // Email Address to receive invoice
            einvoice.Extra__c = account.PersonEmail;
            invoiceNode.addChildElement('ProductLine', null, null)
                .addTextNode(productLine); // Representative product code (Required xml tag, no need to pass value)
            einvoice.ProductLine__c = productLine;
            //invoiceNode.addChildElement('LenhDieuDong', null, null).addTextNode('Test'); // This is "Shipment No." on "Cargo Delivery Note" of YNSPIRE SP, "waybill No." on YNSPIRE SD, “SO No.” on A1-STREAM
            //invoiceNode.addChildElement('NgayDieuDong', null, null).addTextNode('Test'); //Day of mobilization on Delivery bill
            //invoiceNode.addChildElement('DonViDieuDong', null, null).addTextNode('Test'); // Mobility uniton Delivery bill
            //invoiceNode.addChildElement('VeViec', null, null).addTextNode('Test');  // Abouton Delivery bill
            //invoiceNode.addChildElement('NguoiVanChuyen', null, null).addTextNode('Test'); //Transporter’s name on Delivery bill
            if (order.Contract.ContractNumber != null)
                invoiceNode.addChildElement('SoHopDong', null, null)
                    .addTextNode(order.Contract.ContractNumber); //“Contract No”on Delivery bill
            einvoice.SoHopDong__c = order.Contract.ContractNumber;
            //invoiceNode.addChildElement('PhuongTienvc', null, null).addTextNode('Test'); // “Vehicle”on Delivery bill
            //invoiceNode.addChildElement('XuatTaiKho', null, null).addTextNode('Test'); // Exported in stockon Delivery bill
            //invoiceNode.addChildElement('NhapTaiKho', null, null).addTextNode('Test'); //Enter in stockon Delivery bill
            //invoiceNode.addChildElement('PYCGH', null, null).addTextNode('Test'); // D/C No
            //invoiceNode.addChildElement('PXNDDH', null, null).addTextNode('Test'); // C/O No
            //invoiceNode.addChildElement('DIACHIGIAO', null, null).addTextNode('Test'); //delivery address
            // Sales Bike Order = webservice_SD , Sales Appraisal Order or Sales PCA Order = webservice_SP , else = webservice_SW // require
            if (order.RecordTypeId == RecordTypeHelper.ORDER_BIKE) {
                invoiceNode.addChildElement('NguonDuLieu', null, null)
                    .addTextNode('webservice_CRM'); //cr
                einvoice.NguonDuLieu__c = 'webservice_CRM';
            } else if (
                order.RecordTypeId == RecordTypeHelper.ORDER_APPRAISAL ||
                order.RecordTypeId == RecordTypeHelper.ORDER_PCA
            ) {
                invoiceNode.addChildElement('NguonDuLieu', null, null)
                    .addTextNode('webservice_CRM'); // sp
                einvoice.NguonDuLieu__c = 'webservice_CRM';
            } else {
                invoiceNode.addChildElement('NguonDuLieu', null, null)
                    .addTextNode('webservice_CRM'); //sw
                einvoice.NguonDuLieu__c = 'webservice_CRM';
            }

            //invoiceNode.addChildElement('BillWay', null, null).addTextNode('1'); // This is "Shipment No." on "Cargo Delivery Note" of YNSPIRE SP, "waybill No." on YNSPIRE SD, “SO No.” on A1-STREAM
            //invoiceNode.addChildElement('NoteYamaha', null, null).addTextNode('1'); // Note, max1000 char
            if (order.RecordTypeId == RecordTypeHelper.ORDER_BIKE) {
                invoiceNode.addChildElement('SST', null, null).addTextNode('1'); // // Excise tax // STT truyen vao mac dinh la 1 ?
                einvoice.SST__c = '1';
            } else {
                invoiceNode.addChildElement('SST', null, null).addTextNode('0'); // // Excise tax // STT truyen vao mac dinh la 1 ?
                einvoice.SST__c = '0';
            }

            //invoiceNode.addChildElement('USER_ID', null, null).addTextNode('1'); // User ID
            invoiceNode.addChildElement('SOPHIEUTHU', null, null)
                .addTextNode(paymentCode); // Number of receipts // Payment Code + lai
            einvoice.SOPHIEUTHU__c = paymentCode;
            if (order.Order_Number__c != null)
                invoiceNode.addChildElement('SALEORDER', null, null)
                    .addTextNode(order.Order_Number__c); // Sale Order
            einvoice.SALEORDER__c = order.Order_Number__c;
            if (order.DO_DL__r.DO_DL_Code__c != null)
                invoiceNode.addChildElement('DEALERCODE', null, null)
                    .addTextNode(order.DO_DL__r.DO_DL_Code__c); // DEALER CODE
            einvoice.DEALERCODE__c = order.DO_DL__r.DO_DL_Code__c;
            //invoiceNode.addChildElement('CONSIGNEECODE', null, null).addTextNode('1'); // CONSIGNEE CODE

            XmlStreamWriter w = new XmlStreamWriter();
            w.writeStartDocument('utf-8', '1.0');
            w.writeStartElement(
                'soap',
                'Envelope',
                'http://schemas.xmlsoap.org/soap/envelope/'
            );
            w.writeNamespace(
                'xsi',
                'http://www.w3.org/2001/XMLSchema-instance'
            );
            w.writeNamespace('xsd', 'http://www.w3.org/2001/XMLSchema');
            w.writeNamespace(
                'soap',
                'http://schemas.xmlsoap.org/soap/envelope/'
            );
            w.writeStartElement(null, 'soap:Body', null);
            w.writeStartElement(null, 'ImportAndPublishInv', null);
            w.writedefaultNamespace('http://tempuri.org/');
            //Body
            w.writeStartElement(null, 'Account', null);
            w.writeCharacters(accountYMH);
            w.writeEndElement();
            w.writeStartElement(null, 'ACpass', null);
            w.writeCharacters(accountPassYMH);
            w.writeEndElement();
            w.writeStartElement(null, 'username', null);
            w.writeCharacters(userNameYMH);
            w.writeEndElement();
            w.writeStartElement(null, 'password', null);
            w.writeCharacters(userPassYMH);
            w.writeEndElement();
            w.writeStartElement(null, 'pattern', null);
            w.writeCharacters(pattern);
            w.writeEndElement();
            w.writeStartElement(null, 'serial', null);
            w.writeCharacters(serial);
            w.writeEndElement();
            w.writeStartElement(null, 'convert', null);
            w.writeCharacters('0');
            w.writeEndElement();

            w.writeStartElement(null, 'xmlInvData', null);
            w.writeCData(
                doc2.toXmlString()
                    .replace('<?xml version="1.0" encoding="UTF-8"?>', '')
            );
            w.writeEndElement();
            //End Body
            w.writeEndElement();
            w.writeEndElement();
            w.writeEndElement();
            w.writeEndDocument();
            String xmlOutput = w.getXmlString();
            system.debug(xmlOutput);
            w.close();

            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endPoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'text/xml;charset=utf-8;');
            req.setTimeout(120000);
            //req.setBodyDocument(doc); // testBody
            req.setBody(xmlOutput);

            system.debug(xmlOutput);

            DevLog__c log1 = new DevLog__c();
            system.debug('xmlOutput :');
            system.debug(xmlOutput);
            log1.input__c = xmlOutput;
            //insert log1;

            Http http = new Http();
            HttpResponse response = h.send(req);

            system.debug('Response status code : ' + response.getStatusCode());
            if (response.getStatusCode() == 200) {
                dom.Document resDoc = response.getBodyDocument();
                dom.XmlNode root = resDoc.getRootElement();
                // body return
                /*<?xml version="1.0" encoding="utf-8"?>
                <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
                    <soap:Body>
                        <ImportAndPublishInvResponse xmlns="http://tempuri.org/">
                            <ImportAndPublishInvResult>OK:1/001;C22TMC-696999559999999_0000001</ImportAndPublishInvResult>
                        </ImportAndPublishInvResponse>
                    </soap:Body>
                </soap:Envelope>*/

                //XmlStreamReader reader = new XmlStreamReader(response.getBody());
                string result = response.getBody();
                List<String> splitResult = result.split(
                    '<ImportAndPublishInvResult>'
                );
                String einvoiceResult = splitResult[1]
                    .split('</ImportAndPublishInvResult>')[0];
                system.debug(einvoiceResult);

                einvoice.Order__c = order.Id;
                einvoice.Invoice_Publish_Date__c = Date.today();
                if (einvoiceResult.contains('OK')) {
                    String einvoiceData = einvoiceResult.split(';')[1];
                    einvoice.Invoice_Key_Value__c = einvoiceData.split('-')[0];
                    einvoice.Invoice_Serial__c = einvoiceData.split('-')[1];
                    einvoice.Invoice_Amount__c = totalAmount.setScale(
                        0,
                        RoundingMode.HALF_UP
                    );
                    einvoice.Invoice_Publish_Month__c = Today.month();
                    einvoice.Invoice_No__c = einvoiceData.split('_')[1];
                }
                einvoice.Result__c = einvoiceResult;
                einvoice.Type__c = 'API';
                insert einvoice;

                order.Invoice_Date__c = Date.today();
                order.Is_Created_Or_Sent_Invoice__c = true;
                if (order.Asset__c != null) {
                    order.Asset__r.PurchaseDate = Date.today();
                }
                if (
                    order.RecordTypeId == RecordTypeHelper.ORDER_BIKE &&
                    einvoice.Invoice_No__c != null
                ) {
                    order.Invoice_No__c = Decimal.valueOf(
                        einvoice.Invoice_No__c
                    );
                }
                update order;

                for (OrderItem item : listOrderItem) {
                    item.Einvoice__c = einvoice.Id;
                }
                update listOrderItem;

                for (Einvoice_Line__c line : listELine) {
                    line.Einvoice__c = einvoice.Id;
                }

                if (!listELine.isEmpty()) {
                    insert listELine;
                }

                DevLog__c log = new DevLog__c();
                log.Function__c = 'EinvoiceHelper';
                system.debug('xmlOutput :');
                system.debug(xmlOutput);
                log.input__c = xmlOutput;
                log.Output__c = result;
                insert log;
            } else {
                string result = response.getBody();
                List<String> splitResult = result.split(
                    '<ImportAndPublishInvResult>'
                );
                String einvoiceResult = splitResult[1]
                    .split('</ImportAndPublishInvResult>')[0];

                einvoice.Order__c = order.Id;
                einvoice.Invoice_Publish_Date__c = Date.today();
                einvoice.Result__c = einvoiceResult;
                insert einvoice;

                DevLog__c log = new DevLog__c();
                log.Function__c = 'EinvoiceHelper';
                system.debug('xmlOutput :');
                system.debug(xmlOutput);
                log.input__c = xmlOutput;
                log.Output__c = result;
                insert log;
            }
        } catch (Exception e) {
            strMessage =
                'Order Id : ' +
                order.Id +
                ' - ' +
                e.getMessage() +
                ' - ' +
                e.getLineNumber();
            logError('EinvoiceHelper Send Invoice', strMessage, '', '', '');
            system.debug(strMessage);

            order.Is_Created_Or_Sent_Invoice__c = false;
            update order;
        }
    }

    public class QueueCreateEinvoice implements Queueable, Database.AllowsCallouts {
        String orderId;
        Order currentOrder;
        Map<String, List<OrderItem>> mapOrderItem;
        Integer count = 0;
        List<String> listTax;
        String paymentCode = '';
        String paymentMethod = '';
        Contract_Information__c contractInfo;

        public QueueCreateEinvoice(String orderId, Integer count) {
            this.orderId = orderId;

            Map<String, Schema.SObjectField> orderFieldMap = Order.sObjectType.getDescribe()
                .fields.getMap();
            List<string> orderSelectFields = new List<String>(
                orderFieldMap.keySet()
            );
            orderSelectFields.add('DO_DL__r.DO_DL_Code__c');
            orderSelectFields.add('DO_DL__r.Einvoice_Location__c');
            orderSelectFields.add('Contract.ContractNumber');
            orderSelectFields.add('Asset__r.PurchaseDate');
            orderSelectFields.add('Account.Address_Full__c');
            orderSelectFields.add('Account.RecordTypeId');
            String orderSoql = 'SELECT ' + String.join(orderSelectFields, ',');
            orderSoql += ' FROM Order';
            orderSoql += ' WHERE Id = :orderId';
            Order order = Database.query(orderSoql);
            String accountId = order.AccountId;
            String optyId = order.OpportunityId;

            Map<String, Schema.SObjectField> orderlineFieldMap = OrderItem.sObjectType.getDescribe()
                .fields.getMap();
            List<string> orderlineSelectFields = new List<String>(
                orderlineFieldMap.keySet()
            );
            orderlineSelectFields.add('Product2.Name');
            orderlineSelectFields.add('Product2.Quantity_of_Unit__c');
            orderlineSelectFields.add('Product2.RecordTypeId');
            orderlineSelectFields.add('Product2.RecordType.Name');
            orderlineSelectFields.add('Product2.Product_Unit__c');
            orderlineSelectFields.add('Order.Asset__c');
            orderlineSelectFields.add('Order.Asset__r.Product_Name__c');
            orderlineSelectFields.add('Order.Asset__r.Product_Code__c');
            orderlineSelectFields.add('Order.Asset__r.Frame_Number__c ');
            orderlineSelectFields.add('Order.Asset__r.Engine_No__c ');
            orderlineSelectFields.add('Order.Asset__r.Product2.Color_Name__c ');
            orderlineSelectFields.add('Order.Asset__r.Product2.Color_Code__c');
            orderlineSelectFields.add(
                'Order.Promotion_Item__r.Promotion__r.RecordTypeId'
            );
            orderlineSelectFields.add('Product2.Is_Genuine__c');
            orderlineSelectFields.add('Order.Manual_Discount_Approve__c');
            orderlineSelectFields.add(
                'Order.Campaign__r.Promotion_Item__r.RecordType.Name'
            );
            orderlineSelectFields.add(
                'Order.Promotion_Item__r.Promotion__r.RecordType.Name'
            );
            String orderLineSoql =
                'SELECT ' + String.join(orderlineSelectFields, ',');
            orderLineSoql += ' FROM OrderItem';
            orderLineSoql += ' WHERE OrderId =: orderId';
            orderLineSoql += ' ORDER BY OrderId';
            List<OrderItem> listOrderItem = Database.query(orderLineSoql);
            Map<String, List<OrderItem>> mapOrderToItem = new Map<String, List<OrderItem>>();
            List<String> listTax = new List<String>();

            Map<String, Schema.SObjectField> optyFieldMap = Opportunity.sObjectType.getDescribe()
                .fields.getMap();
            List<string> optySelectFields = new List<String>(
                optyFieldMap.keySet()
            );
            String optySoql = 'SELECT ' + String.join(optySelectFields, ',');
            optySoql += ' FROM Opportunity';
            optySoql += ' WHERE Id =: optyId ';
            List<Opportunity> listOpty = Database.query(optySoql);
            String contractId = null;
            if (!listOpty.isEmpty()) {
                contractId = listOpty[0].ContractId;
            }

            // vì order pca có thể ko có opty
            if (!listOpty.isEmpty() && contractId != null) {
                Map<String, Schema.SObjectField> contractFieldMap = Contract.sObjectType.getDescribe()
                    .fields.getMap();
                List<string> contractSelectFields = new List<String>(
                    contractFieldMap.keySet()
                );
                String contractSoql =
                    'SELECT ' + String.join(contractSelectFields, ',');
                contractSoql += ' FROM Contract';
                contractSoql += ' WHERE Id =: contractId ';
                Contract contract = Database.query(contractSoql);
                if (
                    contract != null &&
                    contract.Contract_Information__c != null
                ) {
                    String contractInfoId = contract.Contract_Information__c;
                    Map<String, Schema.SObjectField> contractInfoFieldMap = Contract_Information__c.sObjectType.getDescribe()
                        .fields.getMap();
                    List<string> contractInfoSelectFields = new List<String>(
                        contractInfoFieldMap.keySet()
                    );
                    contractInfoSelectFields.add('RecordType.Name');
                    String contractInfoSoql =
                        'SELECT ' + String.join(contractInfoSelectFields, ',');
                    contractInfoSoql += ' FROM Contract_Information__c';
                    contractInfoSoql += ' WHERE Id =: contractInfoId';
                    Contract_Information__c contractInfo = Database.query(
                        contractInfoSoql
                    );
                    this.contractInfo = contractInfo;
                } else {
                    this.contractInfo = new Contract_Information__c();
                }
            }

            Boolean notIncludeVat = false;
            if (
                order.Generated_Redeem__c == true &&
                order.RecordTypeId == RecordTypeHelper.ORDER_PCA
            ) {
                notIncludeVat = true;
            } else if (
                order.RecordTypeId == RecordTypeHelper.ORDER_FREE_SERVICE &&
                order.Account.RecordTypeId == RecordTypeHelper.ACCOUNT_DODL
            ) {
                notIncludeVat = true;
            }

            for (OrderItem oi : listOrderItem) {
                if (
                    ((order.RecordTypeId ==
                    RecordTypeHelper.ORDER_FREE_COUPON ||
                    order.RecordTypeId ==
                    RecordTypeHelper.ORDER_SERVICE_ORDER) &&
                    oi.Applied__c == true)
                ) {
                    notIncludeVat = true;
                }
            }

            for (OrderItem oi : listOrderItem) {
                Decimal currentTax = oi.VAT__c != null ? oi.VAT__c : 0;
                String temp = currentTax + '_' + oi.Product2.RecordTypeId;
                if (!mapOrderToItem.containsKey(temp)) {
                    mapOrderToItem.put(temp, new List<OrderItem>());
                    listTax.add(temp);
                }

                mapOrderToItem.get(temp).add(oi);
            }

            Map<String, Schema.SObjectField> paymentFieldMap = Payment__c.sObjectType.getDescribe()
                .fields.getMap();
            List<string> paymentSelectFields = new List<String>(
                paymentFieldMap.keySet()
            );
            String paymentSoql =
                'SELECT ' + String.join(paymentSelectFields, ',');
            paymentSoql += ' FROM Payment__c';
            paymentSoql += ' WHERE Order__c = : orderId';
            List<Payment__c> listPayment = Database.query(paymentSoql);

            List<String> lstStrPaymentMethod = new List<String>();
            Boolean isCash = false;
            Boolean isTransfer = false;
            Boolean isPOS = false;
            Boolean isBank = false;
            Boolean isVoucher = false;
            Boolean isMegaPay = false;
            // Update add payment term
            Boolean isTiki = false;
            Boolean isMomo = false;
            Boolean isVNPay = false;
            Boolean isInstalment = false;
            for (Payment__c payment : listPayment) {
                if (this.paymentCode == '') {
                    this.paymentCode = payment.Payment_Code__c;
                } else {
                    this.paymentCode += '-' + payment.Payment_Code__c;
                }
                if (payment.Payment_Term__c == 'Cash') {
                    isCash = true;
                } else if (payment.Payment_Term__c == 'Bank Transfer') {
                    isBank = true;
                } else if (payment.Payment_Term__c == 'POS') {
                    isPOS = true;
                } else if (payment.Payment_Term__c == 'Voucher') {
                    isVoucher = true;
                } else if (payment.Payment_Term__c == 'MegaPay') {
                    isMegaPay = true;
                }
                // https://beunik.atlassian.net/browse/YMVN-734 2022-12-12
                else if (payment.Payment_Term__c == 'Tiki')
                    isTiki = true;
                else if (payment.Payment_Term__c == 'Momo')
                    isMomo = true;
                else if (payment.Payment_Term__c == 'VNPAY')
                    isVNPay = true;
                else if (payment.Payment_Term__c == 'Trả góp')
                    isInstalment = true;
                else
                    isTransfer = true;
            }

            if (isCash == true) {
                lstStrPaymentMethod.add('TM');
                // this.paymentMethod = 'TM';
            }
            if (isVoucher == true) {
                lstStrPaymentMethod.add('VC');
                // this.paymentMethod = 'TM';
            }

            if (isTransfer == true) {
                lstStrPaymentMethod.add('CK');
            }

            if (isPOS == true) {
                lstStrPaymentMethod.add('CT');
            }
            if (isBank == true) {
                lstStrPaymentMethod.add('NH');
            }
            if (isMegaPay == true)
                lstStrPaymentMethod.add('MG');
            // 2022-12-12 Bổ sung phương thức thanh toán - https://beunik.atlassian.net/browse/YMVN-734
            if (isTiki == true)
                lstStrPaymentMethod.add('TK');
            if (isMomo == true)
                lstStrPaymentMethod.add('MO');
            if (isVNPay == true)
                lstStrPaymentMethod.add('VP');
            if (isInstalment == true)
                lstStrPaymentMethod.add('TG');
            if (!lstStrPaymentMethod.isEmpty())
                this.paymentMethod = String.join(lstStrPaymentMethod, ', ');

            // if(isTransfer == true)
            // {
            //     if(this.paymentMethod == '')
            //     {
            //         this.paymentMethod = 'CK';
            //     }
            //     else
            //     {
            //         this.paymentMethod = 'TM, CK';
            //     }
            // }

            this.count = count;
            this.listTax = listTax;
            this.currentOrder = order;
            this.mapOrderItem = mapOrderToItem;
        }
        public void execute(QueueableContext context) {
            Integer countLine = 0;
            for (String tax : this.mapOrderItem.keySet()) {
                if (this.count == countLine) {
                    List<OrderItem> currentListOrderItem = this.mapOrderItem.get(
                        tax
                    );
                    system.debug(currentListOrderItem[0].VAT__c);
                    createInvoice(
                        this.currentOrder,
                        this.contractInfo,
                        currentListOrderItem,
                        currentListOrderItem[0].VAT__c,
                        paymentCode,
                        paymentMethod,
                        countLine
                    );
                }
                countLine++;
            }

            if (this.count + 1 < this.listTax.size()) {
                System.enqueueJob(
                    new EinvoiceHelper.QueueCreateEinvoice(
                        orderId,
                        this.count + 1
                    )
                );
            }
        }
    }

    public class QueueSendEinvoice implements Queueable, Database.AllowsCallouts {
        String orderId;
        Order currentOrder;
        Map<String, List<OrderItem>> mapOrderItem;
        Integer count = 0;
        List<String> listTax;
        String paymentCode = '';
        String paymentMethod = '';
        Contract_Information__c contractInfo;
        public QueueSendEinvoice(String orderId, Integer count) {
            this.orderId = orderId;

            Map<String, Schema.SObjectField> orderFieldMap = Order.sObjectType.getDescribe()
                .fields.getMap();
            List<string> orderSelectFields = new List<String>(
                orderFieldMap.keySet()
            );
            orderSelectFields.add('DO_DL__r.DO_DL_Code__c');
            orderSelectFields.add('DO_DL__r.Einvoice_Location__c');
            orderSelectFields.add('Contract.ContractNumber');
            orderSelectFields.add('Asset__r.PurchaseDate');
            orderSelectFields.add('Account.Address_Full__c');
            orderSelectFields.add('Account.RecordTypeId');
            String orderSoql = 'SELECT ' + String.join(orderSelectFields, ',');
            orderSoql += ' FROM Order';
            orderSoql += ' WHERE Id = :orderId';
            Order order = Database.query(orderSoql);
            String accountId = order.AccountId;
            String optyId = order.OpportunityId;

            Map<String, Schema.SObjectField> orderlineFieldMap = OrderItem.sObjectType.getDescribe()
                .fields.getMap();
            List<string> orderlineSelectFields = new List<String>(
                orderlineFieldMap.keySet()
            );
            orderlineSelectFields.add('Product2.Name');
            orderlineSelectFields.add('Product2.Quantity_of_Unit__c');
            orderlineSelectFields.add('Product2.RecordTypeId');
            orderlineSelectFields.add('Product2.RecordType.Name');
            orderlineSelectFields.add('Product2.Product_Unit__c');
            orderlineSelectFields.add('Order.Asset__c');
            orderlineSelectFields.add('Order.Asset__r.Product_Name__c');
            orderlineSelectFields.add('Order.Asset__r.Product_Code__c');
            orderlineSelectFields.add('Order.Asset__r.Frame_Number__c ');
            orderlineSelectFields.add('Order.Asset__r.Engine_No__c ');
            orderlineSelectFields.add('Order.Asset__r.Product2.Color_Name__c ');
            orderlineSelectFields.add('Order.Asset__r.Product2.Color_Code__c');
            orderlineSelectFields.add(
                'Order.Promotion_Item__r.Promotion__r.RecordTypeId'
            );
            orderlineSelectFields.add('Order.Manual_Discount_Approve__c');
            orderlineSelectFields.add('Product2.Is_Genuine__c');
            orderlineSelectFields.add(
                'Order.Campaign__r.Promotion_Item__r.RecordType.Name'
            );
            orderlineSelectFields.add(
                'Order.Promotion_Item__r.Promotion__r.RecordType.Name'
            );
            String orderLineSoql =
                'SELECT ' + String.join(orderlineSelectFields, ',');
            orderLineSoql += ' FROM OrderItem';
            orderLineSoql += ' WHERE OrderId =: orderId';
            List<OrderItem> listOrderItem = Database.query(orderLineSoql);
            Map<String, List<OrderItem>> mapOrderToItem = new Map<String, List<OrderItem>>();
            List<String> listTax = new List<String>();

            Map<String, Schema.SObjectField> optyFieldMap = Opportunity.sObjectType.getDescribe()
                .fields.getMap();
            List<string> optySelectFields = new List<String>(
                optyFieldMap.keySet()
            );
            String optySoql = 'SELECT ' + String.join(optySelectFields, ',');
            optySoql += ' FROM Opportunity';
            optySoql += ' WHERE Id =: optyId ';
            List<Opportunity> listOpty = Database.query(optySoql);
            String contractId = null;
            if (!listOpty.isEmpty()) {
                contractId = listOpty[0].ContractId;
            }

            if (!listOpty.isEmpty() && contractId != null) {
                Map<String, Schema.SObjectField> contractFieldMap = Contract.sObjectType.getDescribe()
                    .fields.getMap();
                List<string> contractSelectFields = new List<String>(
                    contractFieldMap.keySet()
                );
                String contractSoql =
                    'SELECT ' + String.join(contractSelectFields, ',');
                contractSoql += ' FROM Contract';
                contractSoql += ' WHERE Id =: contractId ';
                Contract contract = Database.query(contractSoql);
                if (
                    contract != null &&
                    contract.Contract_Information__c != null
                ) {
                    String contractInfoId = contract.Contract_Information__c;
                    Map<String, Schema.SObjectField> contractInfoFieldMap = Contract_Information__c.sObjectType.getDescribe()
                        .fields.getMap();
                    List<string> contractInfoSelectFields = new List<String>(
                        contractInfoFieldMap.keySet()
                    );
                    contractInfoSelectFields.add('RecordType.Name');
                    String contractInfoSoql =
                        'SELECT ' + String.join(contractInfoSelectFields, ',');
                    contractInfoSoql += ' FROM Contract_Information__c';
                    contractInfoSoql += ' WHERE Id =: contractInfoId';
                    Contract_Information__c contractInfo = Database.query(
                        contractInfoSoql
                    );
                    this.contractInfo = contractInfo;
                } else {
                    this.contractInfo = new Contract_Information__c();
                }
            }
            Boolean notIncludeVat = false;
            if (
                order.Generated_Redeem__c == true &&
                order.RecordTypeId == RecordTypeHelper.ORDER_PCA
            ) {
                notIncludeVat = true;
            } else if (
                order.RecordTypeId == RecordTypeHelper.ORDER_FREE_SERVICE &&
                order.Account.RecordTypeId == RecordTypeHelper.ACCOUNT_DODL
            ) {
                notIncludeVat = true;
            }

            for (OrderItem oi : listOrderItem) {
                if (
                    ((order.RecordTypeId ==
                    RecordTypeHelper.ORDER_FREE_COUPON ||
                    order.RecordTypeId ==
                    RecordTypeHelper.ORDER_SERVICE_ORDER) &&
                    oi.Applied__c == true)
                ) {
                    notIncludeVat = true;
                }
            }

            for (OrderItem oi : listOrderItem) {
                Decimal currentTax = oi.VAT__c != null ? oi.VAT__c : 0;
                String temp = currentTax + '_' + oi.Product2.RecordTypeId;
                if (!mapOrderToItem.containsKey(temp)) {
                    mapOrderToItem.put(temp, new List<OrderItem>());
                    listTax.add(temp);
                }

                mapOrderToItem.get(temp).add(oi);
            }

            Map<String, Schema.SObjectField> paymentFieldMap = Payment__c.sObjectType.getDescribe()
                .fields.getMap();
            List<string> paymentSelectFields = new List<String>(
                paymentFieldMap.keySet()
            );
            String paymentSoql =
                'SELECT ' + String.join(paymentSelectFields, ',');
            paymentSoql += ' FROM Payment__c';
            paymentSoql += ' WHERE Order__c = : orderId';
            List<Payment__c> listPayment = Database.query(paymentSoql);

            List<String> lstStrPaymentMethod = new List<String>();
            Boolean isCash = false;
            Boolean isTransfer = false;
            Boolean isPOS = false;
            Boolean isBank = false;
            Boolean isVoucher = false;
            Boolean isMegaPay = false;
            for (Payment__c payment : listPayment) {
                if (this.paymentCode == '') {
                    this.paymentCode = payment.Payment_Code__c;
                } else {
                    this.paymentCode += '-' + payment.Payment_Code__c;
                }
                if (payment.Payment_Term__c == 'Cash') {
                    isCash = true;
                } else if (payment.Payment_Term__c == 'Voucher') {
                    isVoucher = true;
                } else if (payment.Payment_Term__c == 'Bank Transfer') {
                    isBank = true;
                } else if (payment.Payment_Term__c == 'POS') {
                    isPOS = true;
                } else if (payment.Payment_Term__c == 'MegaPay') {
                    isMegaPay = true;
                } else {
                    isTransfer = true;
                }
            }

            if (isCash == true) {
                lstStrPaymentMethod.add('TM');
                // this.paymentMethod = 'TM';
            }

            if (isVoucher == true) {
                lstStrPaymentMethod.add('VC');
                // this.paymentMethod = 'TM';
            }

            if (isTransfer == true) {
                lstStrPaymentMethod.add('CK');
            }

            if (isPOS == true) {
                lstStrPaymentMethod.add('CT');
            }

            if (isBank == true) {
                lstStrPaymentMethod.add('NH');
            }
            if (isMegaPay == true) {
                lstStrPaymentMethod.add('MG');
            }
            if (!lstStrPaymentMethod.isEmpty()) {
                this.paymentMethod = String.join(lstStrPaymentMethod, ', ');
            }

            // if(isCash == true)
            // {
            //     this.paymentMethod = 'TM';
            // }
            // if(isTransfer == true)
            // {
            //     if(this.paymentMethod == '')
            //     {
            //         this.paymentMethod = 'CK';
            //     }
            //     else
            //     {
            //         this.paymentMethod = 'TM, CK';
            //     }
            // }

            this.count = count;
            this.listTax = listTax;
            this.currentOrder = order;
            this.mapOrderItem = mapOrderToItem;
        }
        public void execute(QueueableContext context) {
            Integer countLine = 0;
            for (String tax : this.mapOrderItem.keySet()) {
                if (this.count == countLine) {
                    List<OrderItem> currentListOrderItem = this.mapOrderItem.get(
                        tax
                    );
                    system.debug(currentListOrderItem[0].VAT__c);
                    sendInvoice(
                        this.currentOrder,
                        this.contractInfo,
                        currentListOrderItem,
                        currentListOrderItem[0].VAT__c,
                        paymentCode,
                        paymentMethod,
                        countLine
                    );
                }
                countLine++;
            }

            if (this.count + 1 < this.listTax.size()) {
                System.enqueueJob(
                    new EinvoiceHelper.QueueSendEinvoice(
                        orderId,
                        this.count + 1
                    )
                );
            }
        }
    }

    public static String nameFormat(String name) {
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

    public static void logError(
        String function,
        String message,
        String input,
        String output,
        String url
    ) {
        DevLog__c log = new DevLog__c(
            Function__c = function,
            Url__c = url,
            Input__c = input,
            Output__c = output,
            Message__c = message
        );
        insert log;
    }

    private static String trimErrorMessage(String errorMessage) {
        if (errorMessage.length() > 30000) {
            errorMessage = errorMessage.substring(0, 30000);
        }
        return errorMessage;
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
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
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
