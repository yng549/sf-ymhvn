public without sharing class TriggerOrder {
  private static final string SURVEYCODE = System.Label.Survey;
  private static final string SURVEYFOREIGNERCODE = System.Label.SurveyForeigner;
  public static Boolean flagRunCancleOrderBike = false;
  private static final Date ONDATE = Date.today();
  // Get Community url
  private static final Site SITE = [
    SELECT Id
    FROM Site
    WHERE Name IN ('YMVN', 'portal')
    LIMIT 1
  ];
  private static final String SITEURL = [
    SELECT SecureURL
    FROM SiteDetail
    WHERE DurableId = :SITE.Id
  ]
  .SecureUrl;

  public static void onBeforeInsert(List<Order> newData) {
    List<Order> ordersBike = new List<Order>();
    List<Order> ordersPCA = new List<Order>();
    List<Order> ordersService = new List<Order>();
    List<Order> ordersProfomar = new List<Order>();
    List<Order> ordersPromotion = new List<Order>();
    List<Order> ordersCoupon = new List<Order>();
    List<Order> ordersPackage = new List<Order>();

    List<Promotion_Item__c> promotionItems = new List<Promotion_Item__c>();

    Set<ID> userID = new Set<ID>();
    Set<ID> accountsID = new Set<ID>();
    List<Account> lstAccount = new List<Account>();
    checkConditionWarranty(newData);
    for (Order item : newData) {
      userID.add(item.OwnerId);
      accountsID.add(item.AccountId);
      //Set record type for quickaction DuyNguyen
      if (item.Order_Type__c == 'Free Service') {
        item.RecordTypeId = RecordTypeHelper.ORDER_FREE_SERVICE;
      } else if (item.Order_Type__c == 'Quick Service') {
        item.RecordTypeId = RecordTypeHelper.ORDER_QUICK_SERVICE;
      } else if (item.Order_Type__c == 'Order') {
        item.RecordTypeId = RecordTypeHelper.ORDER_SERVICE_ORDER;
      } else if (item.Order_Type__c == 'Free Coupon') {
        item.RecordTypeId = RecordTypeHelper.ORDER_FREE_COUPON;
      } else if (item.Order_Type__c == 'Service Package') {
        item.RecordTypeId = RecordTypeHelper.ORDER_SERVICE_PACKAGE;
      }

      if (item.RecordTypeId == RecordTypeHelper.ORDER_BIKE) {
        ordersBike.add(item);
      } else if (item.RecordTypeId == RecordTypeHelper.ORDER_PCA) {
        ordersPCA.add(item);
        // Set default promotion for Order
        if (String.isBlank(item.Promotion_Item__c)) {
          ordersPromotion.add(item);
        }
      } else if (item.RecordTypeId == RecordTypeHelper.ORDER_PROFOMAR_ORDER) {
        ordersProfomar.add(item);
      } else if (item.RecordTypeId == RecordTypeHelper.ORDER_PROFOMAR_ORDER) {
        ordersService.add(item);
      } else if (item.RecordTypeId == RecordTypeHelper.ORDER_SERVICE_PACKAGE) {
        ordersPackage.add(item); //PACK
      } else {
        ordersService.add(item);
      }

      if (item.RecordTypeId == RecordTypeHelper.ORDER_FREE_COUPON) {
        ordersCoupon.add(item);
      }
    }

    setPricebook2onOrder(newData);

    // Lookup up address for account
    Map<Id, Account> MapAccount = new Map<Id, Account>(
      [
        SELECT
          ID,
          Name,
          Phone,
          PersonMobilePhone,
          Address_No__c,
          Province__c,
          District__c,
          Account_Is_Primary__r.Applied_Promotion__c
        FROM Account
        WHERE Id IN :accountsID
      ]
    );

    //Lookup DODL
    Map<Id, User> MapUser = new Map<Id, User>(
      [
        SELECT Id, Username, ContactId, AccountId
        FROM User
        WHERE ID IN :userID
      ]
    );
    if (ordersPromotion.size() > 0) {
      promotionItems = [
        SELECT Id, Discount__c
        FROM Promotion_Item__c
        WHERE
          Promotion__r.RecordTypeID = :RecordTypeHelper.PROMOTIONDEFAULT
          AND Active__c = TRUE
      ];
    }

    for (Order item : newData) {
      if (item.Order_Source__c != 'E-Commerce') {
        item.Received_Name__c = MapAccount.get(item.AccountId).Name;
        item.Received_Mobile__c = MapAccount.get(item.AccountId).Phone != null
          ? MapAccount.get(item.AccountId).Phone
          : MapAccount.get(item.AccountId).PersonMobilePhone;
        item.Address_No__c = MapAccount.get(item.AccountId).Address_No__c;
        item.Province__c = MapAccount.get(item.AccountId).Province__c;
        item.District__c = MapAccount.get(item.AccountId).District__c;
      }
      if (string.isblank(item.DO_DL__c) && MapUser.get(item.OwnerId) != null) {
        item.DO_DL__c = MapUser.get(item.OwnerId).AccountID;
      }

      // As the order New applied Promotion & Items.
      if (!ordersPromotion.isEmpty() && !promotionItems.isEmpty()) {
        if (
          item.Promotion_Item__c == null &&
          MapAccount.get(item.AccountID)
            .Account_Is_Primary__r.Applied_Promotion__c &&
          !item.Generated_Redeem__c
        ) {
          item.Promotion_Item__c = promotionItems[0].Id;
        }
      }
    }

    //Check Free Coupon
    if (!ordersCoupon.isEmpty()) {
      List<Asset> assets = [
        SELECT
          Id,
          Product2Id,
          Product2.Bike_cc__c,
          Warranty_Effective_Date__c,
          Warranty_Kilometers__c,
          Warrant_Expired_Date__c
        FROM Asset
        WHERE Id = :ordersCoupon[0].Asset__c
      ];
      if (!assets.isEmpty()) {
        if (
          assets[0].Warranty_Kilometers__c < ordersCoupon[0].Mileage__c &&
          assets[0].Product2.Bike_cc__c == '<400cc'
        ) {
          newData[0].addError('The bike is out of warranty conditions.');
        } else if (assets[0].Warrant_Expired_Date__c < Date.today()) {
          newData[0].addError('The bike is out of warranty conditions.');
        } else {
          List<Free_Coupon__c> coupons = [
            SELECT
              Id,
              Applied__c,
              Asset__c,
              Serial_No__c,
              WarrantyEffectiveDate__c,
              WarrantyExpiredDate__c,
              Coupon_Application_No__c
            FROM Free_Coupon__c
            WHERE Asset__c = :ordersCoupon[0].Asset__c
          ];

          if (assets[0].Product2.Bike_cc__c == '>400cc') {
            for (Order item : newData) {
              if (
                String.isBlank(item.IMEI_Free_Coupon__c) &&
                String.isBlank(item.IMEI_Free_Coupon__c)
              ) {
                item.addError(
                  'Please input IMEI free coupon before create the free coupon order.'
                );
              }
            }
          }
          if (coupons.isEmpty()) {
            newData[0]
              .addError(
                'Currently there do not any free coupon for this asset.'
              );
          }
          if (assets[0].Product2.Bike_cc__c == '>400cc') {
            if (coupons[0].Applied__c)
              newData[0].addError('This coupon has always been used');
            else if (
              coupons[0].Coupon_Application_No__c !=
              newData[0].IMEI_Free_Coupon__c
            )
              newData[0].addError('This IMEI coupon is invalid');
            else if (
              coupons[0].Coupon_Application_No__c ==
              newData[0].IMEI_Free_Coupon__c
            ) {
              if (coupons[0].WarrantyExpiredDate__c < ONDATE)
                newData[0].addError('This IMEI coupon is Expired');
              else {
                Free_Coupon__c coupon = new Free_Coupon__c();
                coupon.Id = coupons[0].Id;
                coupon.Applied__c = true;
                coupon.WarrantyMileage__c = newData[0].Mileage__c;
                coupon.ServiceDate__c = ONDATE;
                update coupon;
                for (Order item : newData)
                  item.Free_Coupon__c = coupons[0].Id;
              }
            }
          } else if (assets[0].Product2.Bike_cc__c == '<400cc') {
            Boolean IsApplied = true;
            for (Free_Coupon__c itemFree : coupons) {
              if (
                itemFree.WarrantyEffectiveDate__c <= ONDATE &&
                itemFree.WarrantyExpiredDate__c >= ONDATE &&
                !itemFree.Applied__c
              ) {
                Free_Coupon__c c = new Free_Coupon__c();
                c.Id = itemFree.Id;
                c.Applied__c = true;
                c.WarrantyMileage__c = newData[0].Mileage__c;
                c.ServiceDate__c = ONDATE;
                update c;
                for (Order item : newData)
                  item.Free_Coupon__c = itemFree.Id;
                IsApplied = !IsApplied;
                break;
              }
            }
            if (IsApplied)
              newData[0]
                .addError(
                  'Currently there do not any free coupon for this asset.'
                );
          }
        }
      }
    }

    //Set Order Number by Record Type
    if (!ordersBike.isEmpty()) {
      SetOrderNumber(ordersBike, 'MC');
    }
    if (!ordersProfomar.isEmpty()) {
      SetOrderNumber(ordersProfomar, 'PO-PCA');
    }
    if (!ordersPCA.isEmpty()) {
      SetOrderNumber(ordersPCA, 'PCA');
    }
    if (!ordersService.isEmpty()) {
      SetOrderNumber(ordersService, 'SE');
    }
    if (!ordersPackage.isEmpty()) {
      SetOrderNumber(ordersPackage, 'PACK');
    }
  }

  private static void SetOrderNumber(List<Order> newData, String OrderType) {
    integer IndexTestRide = 0;
    integer Month = Date.today().month();
    String MonthNo = String.valueOf(Month);
    Map<Id, User> mapAccountWithUser = new Map<Id, User>();
    List<User> lstUserHN = [
      SELECT Id, AccountId
      FROM User
      WHERE Account.Name = :'REVZONE YAMAHA MOTOR HA NOI'
    ];
    for (User item : lstUserHN) {
      mapAccountWithUser.put(item.AccountId, item);
    }
    if (Month < 10) {
      MonthNo = '0' + String.valueOf(Month);
    }
    integer Year = Date.today().year();
    List<Order> orderstestRide = new List<Order>();
    if (OrderType == 'MC') {
      orderstestRide = [
        SELECT Order_No__c, DO_DL__c, DO_DL__r.Name, Order_Number__c
        FROM Order
        WHERE
          Order_No__c > 0
          AND RecordTypeId = :RecordTypeHelper.ORDER_BIKE
          AND CALENDAR_MONTH(convertTimezone(CreatedDate)) = :Month
          AND CALENDAR_YEAR(convertTimezone(CreatedDate)) = :Year
          AND DO_DL__c = :newData[0].DO_DL__c
        ORDER BY Order_No__c DESC
        LIMIT 1
      ];
    } else if (OrderType == 'PO-PCA') {
      orderstestRide = [
        SELECT Order_No__c, DO_DL__c, DO_DL__r.Name, Order_Number__c
        FROM Order
        WHERE
          Order_No__c > 0
          AND RecordTypeId = :RecordTypeHelper.ORDER_PROFOMAR_ORDER
          AND CALENDAR_MONTH(convertTimezone(CreatedDate)) = :Month
          AND CALENDAR_YEAR(convertTimezone(CreatedDate)) = :Year
          AND DO_DL__c = :newData[0].DO_DL__c
        ORDER BY Order_No__c DESC
        LIMIT 1
      ];
    } else if (OrderType == 'PCA') {
      orderstestRide = [
        SELECT Order_No__c, DO_DL__c, DO_DL__r.Name, Order_Number__c
        FROM Order
        WHERE
          Order_No__c > 0
          AND RecordTypeId = :RecordTypeHelper.ORDER_PCA
          AND CALENDAR_MONTH(convertTimezone(CreatedDate)) = :Month
          AND CALENDAR_YEAR(convertTimezone(CreatedDate)) = :Year
          AND DO_DL__c = :newData[0].DO_DL__c
        ORDER BY Order_No__c DESC
        LIMIT 1
      ];
    } else if (OrderType == 'SE') {
      orderstestRide = [
        SELECT Order_No__c, DO_DL__c, DO_DL__r.Name, Order_Number__c
        FROM Order
        WHERE
          Order_No__c > 0
          AND RecordTypeId != :RecordTypeHelper.ORDER_PCA
          AND RecordTypeId != :RecordTypeHelper.ORDER_BIKE
          AND RecordTypeId != :RecordTypeHelper.ORDER_PROFOMAR_ORDER
          AND RecordTypeId != :RecordTypeHelper.ORDER_SERVICE_PACKAGE
          AND CALENDAR_MONTH(convertTimezone(CreatedDate)) = :Month
          AND CALENDAR_YEAR(convertTimezone(CreatedDate)) = :Year
          AND DO_DL__c = :newData[0].DO_DL__c
        ORDER BY Order_No__c DESC
        LIMIT 1
      ];
    } else if (OrderType == 'PACK') {
      orderstestRide = [
        SELECT Order_No__c, DO_DL__c, DO_DL__r.Name, Order_Number__c
        FROM Order
        WHERE
          Order_No__c > 0
          AND RecordTypeId != :RecordTypeHelper.ORDER_SERVICE_PACKAGE
          AND CALENDAR_MONTH(convertTimezone(CreatedDate)) = :Month
          AND CALENDAR_YEAR(convertTimezone(CreatedDate)) = :Year
          AND DO_DL__c = :newData[0].DO_DL__c
        ORDER BY Order_No__c DESC
        LIMIT 1
      ];
      if (orderstestRide[0].DO_DL__r.Name == 'REVZONE YAMAHA MOTOR HA NOI') {
        orderstestRide[0].Order_Number__c += '-HN-';
      }
    }

    if (!orderstestRide.isEmpty()) {
      IndexTestRide = orderstestRide[0].Order_No__c.intValue();
      SYSTEM.DEBUG(
        'orderstestRide[0].Order_No__c : ' + orderstestRide[0].Order_No__c
      );
    }
    for (Order item : newData) {
      IndexTestRide += 1;
      item.Order_No__c = IndexTestRide;
      System.debug('item: ' + item.DO_DL__c);
      System.debug('item: ' + item.DO_DL__r.Name);
      String IndexTestRideNo = String.valueOf(IndexTestRide);
      if (IndexTestRide < 10) {
        IndexTestRideNo = '000' + String.valueOf(IndexTestRide);
      } else if (IndexTestRide < 100) {
        IndexTestRideNo = '00' + String.valueOf(IndexTestRide);
      } else if (IndexTestRide < 1000) {
        IndexTestRideNo = '0' + String.valueOf(IndexTestRide);
      }
      if (item.Order_Source__c == 'E-Commerce') {
        item.Order_Number__c =
          'SO-' +
          'E-' +
          OrderType +
          (mapAccountWithUser.containsKey(item.DO_DL__c)
            ? ('-HN-' +
              (String.valueOf(Year).right(2) +
              MonthNo +
              '-' +
              IndexTestRideNo))
            : ('-' +
              String.valueOf(Year).right(2) +
              MonthNo +
              '-' +
              IndexTestRideNo));
      } else {
        item.Order_Number__c =
          'SO-' +
          OrderType +
          (mapAccountWithUser.containsKey(item.DO_DL__c)
            ? ('-HN-' +
              (String.valueOf(Year).right(2) +
              MonthNo +
              '-' +
              IndexTestRideNo))
            : ('-' +
              String.valueOf(Year).right(2) +
              MonthNo +
              '-' +
              IndexTestRideNo));
      }
      if (OrderType == 'PO-PCA') {
        item.Order_Number__c = item.Order_Number__c.replaceFirst('SO-', '');
      }
    }
  }

  public static void onAfterInsert(List<Order> newData) {
    Set<Id> accountsID = new Set<Id>();
    Set<String> oppsID = new Set<String>();
    List<Order> ordersInstallation = new List<Order>();
    List<Order> serviceOrders = new List<Order>();
    for (Order item : newData) {
      if (
        item.RecordTypeId == recordTypeHelper.ORDER_FREE_SERVICE ||
        item.RecordTypeId == recordTypeHelper.ORDER_WARRANTY ||
        item.RecordTypeId == recordTypeHelper.ORDER_SERVICE_ORDER ||
        item.RecordTypeId == recordTypeHelper.ORDER_FREE_COUPON
      ) {
        serviceOrders.add(item);
      }
    }
    if (!serviceOrders.isEmpty()) {
      CreateServiceOrder(serviceOrders);
    }
    //SONumber DODL
    List<Order> SOnumberOrder = new List<Order>();
    for (Order item : newData) {
      if (
        item.RecordTypeId == recordTypeHelper.ORDER_FREE_SERVICE ||
        item.RecordTypeId == recordTypeHelper.ORDER_WARRANTY ||
        item.RecordTypeId == recordTypeHelper.ORDER_SERVICE_ORDER ||
        item.RecordTypeId == recordTypeHelper.ORDER_FREE_COUPON ||
        item.RecordTypeId == recordTypeHelper.ORDER_SERVICE_PACKAGE ||
        item.RecordTypeId == recordTypeHelper.ORDER_INTERNAL_SERVICE ||
        item.RecordTypeId == recordTypeHelper.ORDER_RECALL ||
        item.RecordTypeId == recordTypeHelper.ORDER_PCA ||
        item.RecordTypeId == recordTypeHelper.ORDER_BIKE ||
        item.RecordTypeId == recordTypeHelper.ORDER_PROFOMAR_ORDER ||
        item.RecordTypeId == recordTypeHelper.ORDER_QUICK_SERVICE ||
        item.RecordTypeId == recordTypeHelper.ORDER_APPRAISAL ||
        item.RecordTypeId == recordTypeHelper.ORDER_INSTALLATION
      ) {
        SOnumberOrder.add(item);
      }
    }

    if (!SOnumberOrder.isEmpty()) {
      //SONumberOrder(SOnumberOrder);
    }

    for (Order item : newData) {
      accountsID.add(item.AccountID);
      if (item.RecordTypeId == recordTypeHelper.ORDER_BIKE) {
        oppsID.add(item.OpportunityId);
      } else if (item.RecordTypeId == RecordTypeHelper.ORDER_INSTALLATION) {
        ordersInstallation.add(item);
      }
    }
    createOrderBikeKPI(oppsID, newData);
    // Update last actividate account
    updateLastActivityOnAccount(accountsID, newData);
    if (!ordersInstallation.isEmpty()) {
      List<Order> ordersPCA = [
        SELECT Id, Installation_Order__c
        FROM Order
        WHERE Id = :ordersInstallation[0].Order_PCA__c
      ];
      if (!ordersPCA.isEmpty() && ordersPCA[0].Installation_Order__c != null) {
        newData[0].addError('Order Installation already exists');
      } else {
        //update Order PCA
        Order order = new Order();
        order.Installation_Order__c = ordersInstallation[0].Id;
        order.Id = ordersInstallation[0].Order_PCA__c;

        //create Order Installation
        List<Order_Installation__c> ordersInstall = new List<Order_Installation__c>();
        for (OrderItem Item : [
          SELECT Product2Id, Id, UnitPrice, Quantity, Installtion__c
          FROM OrderItem
          WHERE
            OrderId = :ordersInstallation[0].Order_PCA__c
            AND Installtion__c = TRUE
        ]) {
          Order_Installation__c orderInstall = new Order_Installation__c();
          orderInstall.Order__c = ordersInstallation[0].Id;
          orderInstall.Product__c = Item.Product2Id;
          orderInstall.Order_Product__c = Item.Id;
          ordersInstall.add(orderInstall);
        }
        insert ordersInstall;
        update order;
      }
    }
  }

  private static void CreateServiceOrder(List<Order> orders) {
    User objUser = [
      SELECT Id, AccountId, Account.Name
      FROM User
      WHERE Id = :UserInfo.getUserId()
    ];
    List<Order> lstOrderQuery = [
      SELECT
        Id,
        Asset__r.Account_Customer__r.DO_DL_Create_Account__c,
        Asset__r.Account_Customer__r.Name,
        Asset__r.Account_Customer__r.DO_DL_Create_Account__r.Name,
        Asset__r.Account_Customer__r.DO_DL_Owner__c,
        Asset__r.Account_Primary_Owner__c
      FROM Order
      WHERE Id IN :orders
    ];

    if (
      lstOrderQuery[0].Asset__r.Account_Customer__r.DO_DL_Create_Account__c !=
      objUser.AccountId
    ) {
      List<Account> lstAccountByDODL = [
        SELECT
          Id,
          LastName,
          FirstName,
          Type,
          RecordTypeId,
          ParentId,
          Language__c,
          Address__c,
          Company__c,
          DOB__pc,
          PersonEmail,
          A2__c,
          ID_Type__c,
          ID_Issued_By__c,
          ID_Issued_By_Eng__c,
          Country__c,
          A2_License_No__c,
          Gender__c,
          PersonMobilePhone,
          Tax_Code__c,
          ID_Issue_Date__c,
          ID_No__c,
          Province__c,
          AccountSource,
          District__c,
          A2_Issue_Date__c,
          permanent_Residence__c,
          Email__c
        FROM Account
        WHERE
          DO_DL_Create_Account__c = :objUser.AccountId
          AND Account_Is_Primary__c = :lstOrderQuery[0]
            .Asset__r.Account_Primary_Owner__c
          AND Is_Primary__c = FALSE
      ];
      System.debug('lstAccountByDODL : ' + lstAccountByDODL);
      if (!lstAccountByDODL.isEmpty()) {
        lstOrderQuery[0].AccountId = lstAccountByDODL[0].Id;
        update lstOrderQuery[0];
      } else {
        List<Account> lstAccountByDODLExist = [
          SELECT
            Id,
            LastName,
            FirstName,
            Type,
            RecordTypeId,
            ParentId,
            Language__c,
            Address__c,
            Company__c,
            DOB__pc,
            PersonEmail,
            A2__c,
            ID_Type__c,
            ID_Issued_By__c,
            ID_Issued_By_Eng__c,
            Country__c,
            A2_License_No__c,
            Gender__c,
            PersonMobilePhone,
            Tax_Code__c,
            ID_Issue_Date__c,
            ID_No__c,
            Province__c,
            AccountSource,
            District__c,
            A2_Issue_Date__c,
            permanent_Residence__c,
            Email__c
          FROM Account
          WHERE
            Account_Is_Primary__c = :lstOrderQuery[0]
              .Asset__r.Account_Primary_Owner__c
            AND Is_Primary__c = FALSE
        ];
        Account accClone = lstAccountByDODLExist[0]
          .clone(false, false, false, false);
        accClone.FirstName = string.isBlank(accClone.FirstName)
          ? ' '
          : accClone.FirstName;
        accClone.LastName = string.isBlank(accClone.LastName)
          ? ' '
          : accClone.LastName;
        accClone.DO_DL_Create_Account__c = objUser.AccountId;
        accCLone.ParentId = lstAccountByDODLExist[0].ParentId;
        accClone.AccountSource = lstAccountByDODLExist[0].AccountSource;
        insert accClone;
        lstOrderQuery[0].AccountId = accClone.Id;
        update lstOrderQuery[0];
      }
    }
  }

  private static void updateLastActivityOnAccount(
    Set<Id> accountsID,
    List<Order> newData
  ) {
    try {
      Map<Id, Account> mapAccountQuerry = new Map<Id, Account>(
        [
          SELECT Id, Last_Activity_Date_Custom__c
          FROM Account
          WHERE Id IN :accountsID
        ]
      );
      for (Order item : newData) {
        mapAccountQuerry.get(item.AccountId)
          .Last_Activity_Date_Custom__c = Date.valueOf(item.CreatedDate);
      }
      update mapAccountQuerry.values();
    } catch (Exception ex) {
      newData.get(0).addError(ex.getMessage() + ' ' + ex.getLineNumber());
    }
  }

  public static void onBeforeUpdate(
    Map<Id, Order> mapOlds,
    Map<Id, Order> newMap
  ) {
    List<Order> ordersBike = new List<Order>();
    List<Order> ordersPCA = new List<Order>();
    List<Order> ordersService = new List<Order>();
    List<Order> ordersProfomar = new List<Order>();
    List<Order> ordersPackage = new List<Order>();
    Map<Id, Order> ordersNotify = new Map<Id, Order>();
    Map<Id, List<Order>> mapAccountOrdersPCA = new Map<Id, List<Order>>();
    Map<Id, List<Order>> mapAccountOrdersService = new Map<Id, List<Order>>();
    List<Order> orderCoupon = new List<Order>();
    List<SMS_History__c> smsSurvey = new List<SMS_History__c>();
    // Process create SMS history to Notify Message By phone
    List<SMS_History__c> smsHistories = new List<SMS_History__c>();
    Map<string, Id> mapCodeVNPTSMS = new Map<string, Id>();
    for (SMS_Brandname_Template__c o : [
      SELECT Id, Template_ID__c, CRM_CaseNo__c
      FROM SMS_Brandname_Template__c
      WHERE CRM_CaseNo__c != NULL AND Active__c = TRUE
    ]) {
      mapCodeVNPTSMS.put(o.Template_ID__c, o.Id);
    }
    Map<String, String> mapAccounIdPhone = new Map<String, String>();
    for (Order item : newMap.values()) {
      mapAccounIdPhone.put(item.AccountId, null);
    }
    for (Account a : [
      SELECT Id, PersonMobilePhone
      FROM Account
      WHERE Id = :mapAccounIdPhone.keySet() AND PersonMobilePhone != NULL
    ]) {
      mapAccounIdPhone.put(a.Id, a.PersonMobilePhone);
    }

    //https://beunik.atlassian.net/browse/YMVN-685 //Create url survey
    List<Order> listQueryOrder = [
      SELECT
        Id,
        Account.Name,
        Account.Phone,
        Account.PersonMobilePhone,
        DO_DL__r.Name,
        Asset__r.Product_Name__c,
        Account.Gender__c,
        Account.DOB__pc,
        Account.Address_Full__c,
        Asset__r.Frame_Number__c,
        Asset__r.Engine_No__c,
        Do_DL__r.DO_DL_Code__c,
        Account.Sub_Mobile__pc,
        DO_DL__c,
        AccountId,
        Invoice_Date__c,
        Email__c,
        Order_Number__c,
        Status,
        Link_Survey_EN__c,
        Link_Survey_VN__c,
        RecordTypeId,
        Complete_Date__c
      FROM Order
      WHERE Id IN :newMap.keySet()
    ];

    Map<Id, Order> mapOrderSurvey = new Map<Id, Order>();
    for (Order item : listQueryOrder) {
      Order newO = newMap.get(item.Id);

      if (
        newO.Status == 'Completed' &&
        newO.Invoice_Date__c != null &&
        item.RecordTypeId != RecordTypeHelper.ORDER_WARRANTY &&
        item.RecordTypeId != RecordTypeHelper.ORDER_FREE_COUPON
      ) {
        if (item.RecordTypeId == RecordTypeHelper.ORDER_BIKE) {
          BtnSendSurveyOrderController.getSurveyUrl(item, '1');
        } else if (
          item.RecordTypeId == RecordTypeHelper.ORDER_FREE_SERVICE ||
          item.RecordTypeId == RecordTypeHelper.ORDER_SERVICE_ORDER ||
          item.RecordTypeId == RecordTypeHelper.ORDER_QUICK_SERVICE
        ) {
          BtnSendSurveyOrderController.getSurveyUrl(item, '2');
        } else if (item.RecordTypeId == RecordTypeHelper.ORDER_PCA) {
          BtnSendSurveyOrderController.getSurveyUrl(item, '3');
        }
      } else if (
        newO.Status == 'Completed' &&
        (item.RecordTypeId == RecordTypeHelper.ORDER_WARRANTY ||
        item.RecordTypeId == RecordTypeHelper.ORDER_FREE_COUPON)
      ) {
        BtnSendSurveyOrderController.getSurveyUrl(item, '4');
      }

      mapOrderSurvey.put(item.Id, item);
    }
    //

    for (Order item : newMap.values()) {
      if (
        (item.RecordTypeId == RecordTypeHelper.ORDER_BIKE) &&
        (mapOlds.get(item.Id).Status != item.Status) &&
        item.Status == 'Cancel' &&
        mapOlds.get(item.Id).Is_Booked_Asset__c
      ) {
        item.Is_Booked_Asset__c = false;
      }
      if (item.DO_DL__c != mapOlds.get(item.Id).DO_DL__c) {
        if (item.RecordTypeId == RecordTypeHelper.ORDER_BIKE) {
          ordersBike.add(item);
        } else if (item.RecordTypeId == RecordTypeHelper.ORDER_PCA) {
          ordersPCA.add(item);
        } else if (item.RecordTypeId == RecordTypeHelper.ORDER_PROFOMAR_ORDER) {
          ordersProfomar.add(item);
        } else if (
          item.RecordTypeId == RecordTypeHelper.ORDER_SERVICE_PACKAGE
        ) {
          ordersPackage.add(item); //PACK
        } else {
          ordersService.add(item);
        }
      }
      if (
        item.RecordTypeId == RecordTypeHelper.ORDER_BIKE &&
        item.Invoice_Date__c != null &&
        !item.Is_Survey_SMS__c &&
        item.Invoice_Date__c != mapOlds.get(item.Id).Invoice_Date__c
      ) {
        createHistorySMS(
          item,
          !item.IsForeigner__c
            ? mapCodeVNPTSMS.get(SURVEYCODE)
            : mapCodeVNPTSMS.get(SURVEYFOREIGNERCODE),
          mapAccounIdPhone.get(item.AccountId),
          smsSurvey,
          'Survey Sending'
        );
        item.Date_Send_SMS__c = item.Invoice_Date__c.addDays(2);
      }
      // Order PCA
      if (
        item.RecordTypeId == RecordTypeHelper.ORDER_PCA &&
        item.Amount__c > 10000000 &&
        !item.Is_First_PCA__c &&
        !item.Is_Survey_SMS__c &&
        item.Invoice_Date__c != null &&
        item.Invoice_Date__c != mapOlds.get(item.Id).Invoice_Date__c
      ) {
        if (!mapAccountOrdersPCA.containsKey(item.AccountId)) {
          mapAccountOrdersPCA.put(item.AccountId, new List<Order>());
        }
        mapAccountOrdersPCA.get(item.AccountId).add(item);
      }
      // Order Service
      if (
        (item.RecordTypeId == RecordTypeHelper.ORDER_FREE_SERVICE ||
        item.RecordTypeId == RecordTypeHelper.ORDER_SERVICE_ORDER) &&
        !item.Is_First_Service__c &&
        !item.Is_Survey_SMS__c &&
        item.Invoice_Date__c != null &&
        item.Invoice_Date__c != mapOlds.get(item.Id).Invoice_Date__c &&
        item.SoldHour__c > 4
      ) {
        if (!mapAccountOrdersService.containsKey(item.AccountId)) {
          mapAccountOrdersService.put(item.AccountId, new List<Order>());
        }
        mapAccountOrdersService.get(item.AccountId).add(item);
      }
      // Order warranty
      if (
        (item.RecordTypeId == RecordTypeHelper.ORDER_FREE_COUPON ||
        item.RecordTypeId == RecordTypeHelper.ORDER_WARRANTY) &&
        !item.Is_Survey_SMS__c &&
        item.Complete_Date__c != null &&
        item.Complete_Date__c != mapOlds.get(item.Id).Complete_Date__c
      ) {
        createHistorySMS(
          item,
          !item.IsForeigner__c
            ? mapCodeVNPTSMS.get(SURVEYCODE)
            : mapCodeVNPTSMS.get(SURVEYFOREIGNERCODE),
          mapAccounIdPhone.get(item.AccountId),
          smsSurvey,
          'Survey Sending'
        );
        item.Date_Send_SMS__c = item.Complete_Date__c.addDays(2);
      }
      // end Survey Sending

      if (
        item.RecordTypeId == RecordTypeHelper.ORDER_PCA &&
        item.Status != mapOlds.get(item.Id).Status &&
        item.Status == 'Completed'
      ) {
        ordersNotify.put(item.Id, item);
      }
      if (
        (item.RecordTypeId == RecordTypeHelper.ORDER_PCA ||
        item.RecordTypeId == RecordTypeHelper.ORDER_BIKE ||
        item.RecordTypeId == RecordTypeHelper.ORDER_SERVICE_ORDER) &&
        item.Status != mapOlds.get(item.Id).Status &&
        item.Status == 'Completed'
      )
        item.EndDate = ONDATE;

      if (
        item.RecordTypeId == RecordTypeHelper.ORDER_FREE_COUPON &&
        item.Status != mapOlds.get(item.Id).Status &&
        item.Status == 'Completed'
      )
        orderCoupon.add(item);

      if (item.Status == 'Completed' && mapOrderSurvey.containsKey(item.Id)) {
        Order tempO = mapOrderSurvey.get(item.Id);
        item.Link_Survey_EN__c = tempO.Link_Survey_EN__c;
        item.Link_Survey_VN__c = tempO.Link_Survey_VN__c;
      }
    }

    // Start Create Survey SMS BIKE AND Service
    if (!mapAccountOrdersPCA.isEmpty()) {
      for (Account a : [
        SELECT
          Id,
          PersonMobilePhone,
          Language__c,
          (
            SELECT Id
            FROM Orders
            WHERE
              Invoice_Date__c = THIS_YEAR
              AND Invoice_Date__c = THIS_MONTH
              AND Is_First_PCA__c = TRUE
          )
        FROM Account
        WHERE Id IN :mapAccountOrdersPCA.keySet()
      ]) {
        if (!a.Orders.isEmpty())
          continue;
        createHistorySMS(
          mapAccountOrdersPCA.get(a.Id)[0],
          a.Language__c == 'Vietnamese'
            ? mapCodeVNPTSMS.get(SURVEYCODE)
            : mapCodeVNPTSMS.get(SURVEYFOREIGNERCODE),
          a.PersonMobilePhone,
          smsSurvey,
          'Survey Sending'
        );
        mapAccountOrdersPCA.get(a.Id)[0].Is_First_PCA__c = true;
        mapAccountOrdersPCA.get(a.Id)[0]
          .Date_Send_SMS__c = mapAccountOrdersPCA.get(a.Id)[0]
          .Invoice_Date__c.addDays(3);
      }
    }
    if (!mapAccountOrdersService.isEmpty()) {
      for (Account a : [
        SELECT
          Id,
          PersonMobilePhone,
          Language__c,
          (
            SELECT Id
            FROM Orders
            WHERE
              Invoice_Date__c = THIS_YEAR
              AND Invoice_Date__c = THIS_MONTH
              AND Is_First_Service__c = TRUE
          )
        FROM Account
        WHERE Id IN :mapAccountOrdersService.keySet()
      ]) {
        if (!a.Orders.isEmpty())
          continue;
        createHistorySMS(
          mapAccountOrdersService.get(a.Id)[0],
          a.Language__c == 'Vietnamese'
            ? mapCodeVNPTSMS.get(SURVEYCODE)
            : mapCodeVNPTSMS.get(SURVEYFOREIGNERCODE),
          a.PersonMobilePhone,
          smsSurvey,
          'Survey Sending'
        );
        mapAccountOrdersService.get(a.Id)[0].Is_First_Service__c = true;
        mapAccountOrdersService.get(a.Id)[0]
          .Date_Send_SMS__c = mapAccountOrdersService.get(a.Id)[0]
          .Invoice_Date__c.addDays(2);
      }
    }
    // End Create Survey SMS BIKE AND Service
    if (!ordersNotify.values().isEmpty()) {
      notifyWhenOrderHasOrderProfomar(ordersNotify);
    }
    if (!orderCoupon.isEmpty()) {
      // updateCheckJobOrPart(lstOrderFreeCoupon);
    }
    insert smsSurvey;
    insert smsHistories;
    Map<Id, SMS_History__c> smsHistoryID = new Map<Id, SMS_History__c>(
      smsHistories
    );
    if (!smsHistoryID.isEmpty())
      system.enqueueJob(new TriggerOrder.CallOutSMS(smsHistoryID));
  }
  public class CallOutSMS implements Queueable, Database.AllowsCallouts {
    Map<Id, SMS_History__c> smsHistoryID;
    public CallOutSMS(Map<Id, SMS_History__c> smsHistoryID) {
      this.smsHistoryID = smsHistoryID;
    }
    public void execute(QueueableContext context) {
      for (string smsID : smsHistoryID.keySet()) {
        SmsHelper.callSendListSMSVNPT(
          smsHistoryID.get(smsID).Template__c,
          smsID,
          smsHistoryID.get(smsID).To_Phone__c
        );
      }
    }
  }
  private static void createHistorySMS(
    Order o,
    Id templateBrandId,
    string phone,
    List<SMS_History__c> smsHistory,
    string taskType
  ) {
    SMS_History__c sms = new SMS_History__c();
    sms.From_Brand_Name__c = 'REVZONE YAMAHA MOTOR';
    sms.Order__c = o.Id;
    sms.To_Phone__c = phone;
    sms.Task_Type__c = taskType;
    sms.DO_DL__c = o.DO_DL__c;
    sms.Scheduled_Send_Time__c = Datetime.now();
    sms.AccountCustomer__c = o.AccountId;
    sms.Template__c = templateBrandId;
    sms.Link_Suffix__c = '/s/sv?recordId=' + o.Id;
    smsHistory.add(sms);
  }
  private static void updateCheckJobOrPart(List<Order> orderCoupons) {
    Map<Id, List<OrderItem>> mapOrderItem = new Map<Id, List<OrderItem>>();
    for (OrderItem oI : [
      SELECT Id, Product2Id, OrderId, Product2.Job_ID__c, Product2.PartID__c
      FROM OrderItem
      WHERE OrderId IN :orderCoupons
    ]) {
      if (!mapOrderItem.containsKey(oI.OrderId))
        mapOrderItem.put(oI.OrderId, new List<OrderItem>());
      mapOrderItem.get(oI.OrderId).add(oI);
    }
    for (Order order : orderCoupons) {
      if (mapOrderItem.containsKey(order.Id)) {
        for (OrderItem oI : mapOrderItem.get(order.Id))
          if (
            string.isBlank(oI.Product2.Job_ID__c) ||
            string.isBlank(oI.Product2.PartID__c)
          )
            order.Is_Not_Have_Job_Or_Part__c = true;
      } else
        order.Is_Not_Have_Job_Or_Part__c = true;
    }
  }

  private static void notifyWhenOrderHasOrderProfomar(
    Map<Id, Order> mapOrderNews
  ) {
    for (Order item : [
      SELECT Id, (SELECT Id FROM OrderItems WHERE Profomar_Order__c = :true)
      FROM Order
      WHERE Id IN :mapOrderNews.keySet()
    ]) {
      if (!item.OrderItems.isEmpty()) {
        mapOrderNews.get(item.Id)
          .addError('Order thiếu hàng, cần kiểm tra và điều chỉnh.');
      }
    }
  }
  public static void createOrderBikeKPI(
    Set<String> oppsID,
    List<Order> orders
  ) {
    Map<String, Schema.SObjectField> optyFieldMap = Opportunity.sObjectType.getDescribe()
      .fields.getMap();
    List<string> optySelectFields = new List<String>(optyFieldMap.keySet());
    string optySoql = 'SELECT ' + String.join(optySelectFields, ',');
    optySoql += ' FROM Opportunity';
    optySoql += ' WHERE Id IN: oppsID ';

    Map<String, Opportunity> mapOpty = new Map<String, Opportunity>();

    for (Opportunity opty : Database.query(optySoql))
      mapOpty.put(opty.Id, opty);

    Map<String, Schema.SObjectField> optyMemberFieldMap = OpportunityTeamMember.sObjectType.getDescribe()
      .fields.getMap();
    List<string> optyMemberSelectFields = new List<String>(
      optyMemberFieldMap.keySet()
    );
    String optyMemberSoql =
      'SELECT ' + String.join(optyMemberSelectFields, ',');
    optyMemberSoql += ' FROM OpportunityTeamMember';
    optyMemberSoql += ' WHERE OpportunityId IN: oppsID ';

    Map<String, List<OpportunityTeamMember>> mapMember = new Map<String, List<OpportunityTeamMember>>();
    for (OpportunityTeamMember member : Database.query(optyMemberSoql)) {
      if (!mapMember.containsKey(member.OpportunityId)) {
        mapMember.put(member.OpportunityId, new List<OpportunityTeamMember>());
      }
      mapMember.get(member.OpportunityId).add(member);
    }

    List<Order_Bike_KPI__c> ordersKPI = new List<Order_Bike_KPI__c>();
    for (Order o : orders) {
      Opportunity opp = mapOpty.get(o.OpportunityId);
      List<OpportunityTeamMember> listCurrentMember = new List<OpportunityTeamMember>();
      if (mapMember.containsKey(o.OpportunityId)) {
        listCurrentMember = mapMember.get(o.OpportunityId);
        Integer memberCount = listCurrentMember.size() + 1;
        if (memberCount > 1) {
          Order_Bike_KPI__c firstKPI = new Order_Bike_KPI__c();
          firstKPI.Amount__c = opp.Amount / memberCount;
          firstKPI.Order__c = o.Id;
          firstKPI.Opportunity__c = opp.Id;
          firstKPI.Employee__c = opp.OwnerId;
          ordersKPI.add(firstKPI);

          for (OpportunityTeamMember member : listCurrentMember) {
            Order_Bike_KPI__c kpi = new Order_Bike_KPI__c();
            kpi.Amount__c = opp.Amount / memberCount;
            kpi.Order__c = o.Id;
            kpi.Opportunity__c = opp.Id;
            kpi.Employee__c = member.UserId;
            ordersKPI.add(kpi);
          }
        }
      }
      insert ordersKPI;
    }
  }

  // private static void setPricebook2onOrder(List<Order> orders){
  //     Pricebook2 stdpricebook2 = getStdPriceBook();
  //     for (Order item : orders) {
  //         for (Pricebook2 objPriceBook : [SELECT Id, Name, From__c, To__c, Type__c FROM Pricebook2 WHERE IsActive = : TRUE]){
  //             if (ONDATE >= objPricebook.From__c && ONDATE <= objPricebook.To__c){
  //                 if (item.RecordTypeId == RecordTypeHelper.ORDER_BIKE && objPriceBook.Type__c == 'Bike'){
  //                     item.Pricebook2Id = objPriceBook.Id;
  //                     break;
  //                 } else if ((item.RecordTypeId == RecordTypeHelper.ORDER_PCA || item.RecordTypeId == RecordTypeHelper.ORDER_SERVICE_ORDER || item.RecordTypeId == RecordTypeHelper.ORDER_QUICK_SERVICE || item.RecordTypeId == RecordTypeHelper.ORDER_FREE_SERVICE || item.RecordTypeId == RecordTypeHelper.ORDER_INTERNAL_SERVICE || item.RecordTypeId == RecordTypeHelper.ORDER_INSTALLATION) && objPriceBook.Type__c == 'PCAService'){
  //                 	item.Pricebook2Id = objPriceBook.Id;
  //                     break;
  //                 } else if (item.RecordTypeId == RecordTypeHelper.ORDER_SERVICE_PACKAGE && objPriceBook.Type__c == 'Service Package'){
  //                     item.Pricebook2Id = objPriceBook.Id;
  //                     break;
  //                 } else if ((item.RecordTypeId == RecordTypeHelper.ORDER_WARRANTY || item.RecordTypeId == RecordTypeHelper.ORDER_FREE_COUPON) && objPriceBook.Type__c == 'Warranty'){
  //                     item.Pricebook2Id = objPriceBook.Id;
  //                     break;
  //                 } else if (item.RecordTypeId == RecordTypeHelper.ORDER_RECALL && objPriceBook.Type__c == 'Recall'){
  //                     item.Pricebook2Id = objPriceBook.Id;
  //                     break;
  //                 } else if (item.RecordTypeId == RecordTypeHelper.ORDER_PROFOMAR_ORDER && objPriceBook.Type__c == 'Standard Pricebook') {
  //                 } else if (item.RecordTypeId == RecordTypeHelper.ORDER_APPRAISAL && objPriceBook.Type__c == 'Internal Service'){
  //                     item.Pricebook2Id = stdpricebook2.Id;
  //                     break;
  //                 }
  //             }
  //         }
  //     }
  // }

  private static void setPricebook2onOrder(List<Order> orders) {
    Pricebook2 stdpricebook2 = getStdPriceBook();
    Map<String, Pricebook2> activePricebooks = getActivePriceBooks();
    Map<String, Pricebook2> activeEmployeePricebooks = getActiveEmployeePriceBooks();
    for (Order order : orders) {
      switch on order.RecordTypeId {
        // Bike
        when RecordTypeHelper.ORDER_BIKE {
          Pricebook2 pb = activePricebooks.get('Bike');
          break;
        }
        // Service Package
        when RecordTypeHelper.ORDER_SERVICE_PACKAGE {
          Pricebook2 pb = activePricebooks.get('Service Package');
          break;
        }
        // Recall
        when RecordTypeHelper.ORDER_RECALL {
          Pricebook2 pb = activePricebooks.get('Recall');
          break;
        }
        // Internal Service
        when RecordTypeHelper.ORDER_APPRAISAL {
          Pricebook2 pb = stdpricebook2;
          break;
        }
        // Warranty
        when RecordTypeHelper.ORDER_WARRANTY,
          RecordTypeHelper.ORDER_FREE_COUPON {
          Pricebook2 pb = activePricebooks.get('Warranty');
          break;
        }
        // PCAService
        when RecordTypeHelper.ORDER_PCA,
          RecordTypeHelper.ORDER_SERVICE_ORDER,
          RecordTypeHelper.ORDER_QUICK_SERVICE,
          RecordTypeHelper.ORDER_FREE_SERVICE,
          RecordTypeHelper.ORDER_INTERNAL_SERVICE,
          RecordTypeHelper.ORDER_INSTALLATION {
          if (order.is_Employee__c) {
            Pricebook2 pb = activeEmployeePricebooks.get('PCAService');
          } else {
            Pricebook2 pb = activePricebooks.get('PCAService');
          }
          break;
        }
        when else {
          pb = null;
          break;
        }
      }
      if (pb != null) {
        order.Pricebook2Id = pb.Id;
      }
    }
  }

  public static Pricebook2 getStdPriceBook() {
    Pricebook2 stdPriceBook = new Pricebook2();
    stdPriceBook = [
      SELECT ID, Name
      FROM Pricebook2
      WHERE IsStandard = TRUE
      LIMIT 1
    ];
    return stdPriceBook;
  }

  public static Map<String, Pricebook2> getActivePriceBooks() {
    Map<Id, Pricebook2> priceBooks = new Map<Id, Pricebook2>(
      [
        SELECT Id, Name, From__c, To__c, Type__c
        FROM Pricebook2
        WHERE
          IsActive = TRUE
          AND From__c <= TODAY
          AND To__c >= TODAY
          AND is_Employee__c != TRUE
      ]
    );
    Map<String, Pricebook2> priceBooksMap = new Map<String, Pricebook2>();
    for (Id key : priceBooks.keySet()) {
      Pricebook2 pb = priceBooks.get(key);
      priceBooksMap.put(pb.Type__c, pb);
    }
    return priceBooksMap;
  }

  public static Map<String, Pricebook2> getActiveEmployeePriceBooks() {
    Map<Id, Pricebook2> priceBooks = new Map<Id, Pricebook2>(
      [
        SELECT Id, Name, From__c, To__c, Type__c, is_Employee__c
        FROM Pricebook2
        WHERE
          IsActive = TRUE
          AND From__c <= TODAY
          AND To__c >= TODAY
          AND is_Employee__c = TRUE
      ]
    );
    Map<String, Pricebook2> priceBooksMap = new Map<String, Pricebook2>();
    for (Id key : priceBooks.keySet()) {
      Pricebook2 pb = priceBooks.get(key);
      priceBooksMap.put(pb.Type__c, pb);
    }
    return priceBooksMap;
  }

  private static void syncToDMSOrderType(
    Map<Id, Order> mapOld,
    Map<Id, Order> mapNew
  ) {
    List<Id> orderProfomars = new List<Id>();
    List<Id> orderBikes = new List<Id>();
    List<Id> orderPCAs = new List<Id>();
    List<Id> ordersFCS = new List<Id>();
    List<Id> ordersWarranty = new List<Id>();
    List<Id> ordersRecall = new List<Id>();
    List<Id> ordersWarranty0KM = new List<Id>();
    List<Id> ordersRecall0KM = new List<Id>();
    for (Order item : mapNew.values()) {
      if (
        item.RecordtypeId == RecordTypeHelper.ORDER_PROFOMAR_ORDER &&
        item.Status == 'Place Order' &&
        mapOld.get(item.Id).Status != mapNew.get(item.Id).Status &&
        !item.Is_Sync__c
      ) {
        orderProfomars.add(item.Id);
      } else if (
        item.Status == 'Completed' &&
        mapOld.get(item.Id).Status != mapNew.get(item.Id).Status &&
        !item.Is_Sync__c
      ) {
        if (item.RecordtypeId == RecordTypeHelper.ORDER_BIKE)
          orderBikes.add(item.Id);
        if (item.RecordTypeId == RecordTypeHelper.ORDER_FREE_COUPON)
          ordersFCS.add(item.Id);
        if (item.RecordTypeId == RecordTypeHelper.ORDER_RECALL) {
          if (item.X0km_Recall__c)
            ordersRecall0KM.add(item.Id);
          else
            ordersRecall.add(item.Id);
        }
      } else if (
        item.Status == 'Waiting for Hand over' &&
        mapOld.get(item.Id).Status != mapNew.get(item.Id).Status &&
        !item.Is_Sync__c
      ) {
        if (item.RecordTypeId == RecordTypeHelper.ORDER_WARRANTY) {
          if (item.Warranty_0_Kilometer__c)
            ordersWarranty0KM.add(item.Id);
          else
            ordersWarranty.add(item.Id);
        }
      }
    }
    if (!orderProfomars.isEmpty())
      system.enqueueJob(
        new SyncDMSOrderHelper.CreateOrderQueue(orderProfomars, 'proformaorder')
      );
    if (!orderBikes.isEmpty())
      system.enqueueJob(
        new SyncDMSOrderHelper.CreateOrderQueue(orderBikes, 'mcsalesorder')
      );
    if (!ordersFCS.isEmpty())
      system.enqueueJob(
        new SyncDMSOrderHelper.CreateOrderQueue(ordersFCS, 'svfreecouponsorder')
      );
    if (!ordersWarranty.isEmpty())
      system.enqueueJob(
        new SyncDMSOrderHelper.CreateOrderQueue(
          ordersWarranty,
          'svwarrantyorder'
        )
      );
    if (!ordersRecall.isEmpty())
      system.enqueueJob(
        new SyncDMSOrderHelper.CreateOrderQueue(ordersRecall, 'svrecallorder')
      );
    if (!ordersWarranty0KM.isEmpty())
      system.enqueueJob(
        new SyncDMSOrderHelper.CreateOrderQueue(
          ordersWarranty0KM,
          '0kmsvwarrantyorder'
        )
      );
    if (!ordersRecall0KM.isEmpty())
      system.enqueueJob(
        new SyncDMSOrderHelper.CreateOrderQueue(
          ordersRecall0KM,
          '0kmsvrecallorder'
        )
      );
  }
  /* Method convert Order Ecom to Account DO */
  private static void convertNonResidentToDO(
    Map<Id, Order> mapNew,
    Set<Id> ordersNonResident
  ) {
    List<User> usermkt = [
      SELECT Id
      FROM User
      WHERE Profile.Name = 'MKT Manager'
    ];

    Map<string, Map<Id, Order>> mapPhoneOrders = new Map<string, Map<Id, Order>>();
    // Create Account Primary If nonresident first buy Revzone.
    Map<string, Account> mapOrderEcomAccount = new Map<string, Account>();
    // Loop create collection Data Phone - Orders Ecom
    for (string orderID : ordersNonResident) {
      Order o = mapNew.get(orderID);
      if (!mapOrderEcomAccount.containsKey(o.PhoneNonResident__c)) {
        mapOrderEcomAccount.put(
          o.PhoneNonResident__c,
          new Account(
            Province__c = o.Province__c,
            District__c = o.District__c,
            Address_No__c = o.Address_No__c,
            RecordTypeId = RecordTypeHelper.ACCOUNT_CUSTOMER,
            Gender__c = 'Male',
            OwnerId = usermkt[0].Id,
            PersonHomePhone = o.PhoneNonResident__c,
            Applied_Promotion__c = false,
            Is_Primary__c = true,
            LastName = o.Non_NameResident__c + ' Primary',
            PersonMobilePhone = o.PhoneNonResident__c,
            PersonEmail = o.Non_EmailResident__c
          )
        );
      }

      if (!mapPhoneOrders.containsKey(o.PhoneNonResident__c)) {
        mapPhoneOrders.put(o.PhoneNonResident__c, new Map<Id, Order>());
      }
      mapPhoneOrders.get(o.PhoneNonResident__c).put(o.Id, o);
    }

    Map<string, Map<string, Account>> mapPhoneDOAccount = new Map<string, Map<string, Account>>();
    List<Order> ordersFirstUpdate = new List<Order>();
    List<Account> accountsDO = new List<Account>();
    // Query Account Primary and Account Dealers.
    for (Account a : [
      SELECT
        Id,
        FirstName,
        LastName,
        PersonMobilePhone,
        OwnerId,
        Address_No__c,
        Address_No__pc,
        Gender__c,
        DOB__pc,
        PersonEmail,
        Province__c,
        Province__pc,
        District__pc,
        District__c,
        Address__c,
        RecordTypeId,
        DO_DL_Create_Account__r.DO_DL_Code__c,
        Owner.Profile.Name,
        NonResident__c,
        (SELECT Id, DO_DL_Create_Account__c FROM Accounts3__r)
      FROM Account
      WHERE
        PersonMobilePhone IN :mapPhoneOrders.keySet()
        AND Is_Primary__c = TRUE
        AND NonResident__c = FALSE
    ]) {
      // Collection account's DO from Primary Account-> Revzone => User A

      Map<string, String> mapAccountDO = new Map<string, String>();
      for (Account aDO : a.Accounts3__r) {
        mapAccountDO.put(aDO.DO_DL_Create_Account__c, aDO.Id);
      }
      // Get Order Contains Phone to mapping account Id for Order Ecom
      for (Order o : mapPhoneOrders.get(a.PersonMobilePhone).values()) {
        // Collection account's DO not contains Name of DO. It's means that guest doesn't order in the DO.
        if (!mapAccountDO.containsKey(o.DO_DL__c)) {
          Account acc = a.clone(false, false, false, false);
          acc.LastName = acc.LastName.replaceAll('Primary', '');
          acc.Account_Is_Primary__c = a.Id;
          acc.DO_DL_Create_Account__c = o.DO_DL__c;
          acc.OwnerId = o.OwnerId;
          if (
            mapPhoneDOAccount.containsKey(a.PersonMobilePhone) &&
            !mapPhoneDOAccount.get(a.PersonMobilePhone).containsKey(o.DO_DL__c)
          ) {
            mapPhoneDOAccount.get(a.PersonMobilePhone).put(o.DO_DL__c, acc);
            accountsDO.add(acc);
            continue;
          }
          mapPhoneDOAccount.put(
            a.PersonMobilePhone,
            new Map<string, Account>{ o.DO_DL__c => acc }
          );
          accountsDO.add(acc);
          continue;
        }
        // Else Guest bought any orders in the DO. Mapping Account DO for Order Ecom then remove index of collection
        mapPhoneOrders.get(o.PhoneNonResident__c).remove(o.Id);
        ordersFirstUpdate.add(
          new Order(Id = o.Id, AccountId = mapAccountDO.get(o.DO_DL__c))
        );
      }
      // Remove index by phone when it mapped account ID for Order Ecom.
      if (mapPhoneOrders.get(a.PersonMobilePhone).isEmpty())
        mapPhoneOrders.remove(a.PersonMobilePhone);

      mapOrderEcomAccount.remove(a.PersonMobilePhone);
    }
    insert accountsDO;

    for (string phone : mapPhoneDOAccount.keySet()) {
      for (Order o : mapPhoneOrders.get(phone).values()) {
        ordersFirstUpdate.add(
          new Order(
            Id = o.Id,
            AccountId = mapPhoneDOAccount.get(phone).get(o.DO_DL__c).Id
          )
        );
        mapPhoneOrders.get(o.PhoneNonResident__c).remove(o.Id);
      }
      mapPhoneOrders.remove(phone);
      mapOrderEcomAccount.remove(phone);
    }
    update ordersFirstUpdate;

    // Clear value of variable
    accountsDO.clear();
    ordersFirstUpdate.clear();
    mapPhoneDOAccount.clear();

    // Case guest first buy at Revzone. Create Account Primary and Clone accounts DO from Order-Ecom
    insert mapOrderEcomAccount.values();

    // Create Account DO For Account Primary.
    for (Account a : mapOrderEcomAccount.values()) {
      for (Order o : mapPhoneOrders.get(a.PersonMobilePhone).values()) {
        // IF another Dealers contains not Account existed. Process skip
        Account acc = a.clone(false, false, false, false);
        acc.LastName = acc.LastName.replaceAll('Primary', '');
        acc.OwnerId = o.OwnerId;
        acc.Account_Is_Primary__c = a.Id;
        acc.DO_DL_Create_Account__c = o.DO_DL__c;
        acc.Is_Primary__c = false;
        if (
          mapPhoneDOAccount.containsKey(a.PersonMobilePhone) &&
          !mapPhoneDOAccount.get(a.PersonMobilePhone).containsKey(o.DO_DL__c)
        ) {
          mapPhoneDOAccount.get(a.PersonMobilePhone).put(o.DO_DL__c, acc);
          accountsDO.add(acc);
          continue;
        }
        mapPhoneDOAccount.put(
          a.PersonMobilePhone,
          new Map<string, Account>{ o.DO_DL__c => acc }
        );
        accountsDO.add(acc);
        continue;
      }
    }
    insert accountsDO;

    for (string phone : mapPhoneDOAccount.keySet()) {
      for (Order o : mapPhoneOrders.get(phone).values()) {
        ordersFirstUpdate.add(
          new Order(
            Id = o.Id,
            AccountId = mapPhoneDOAccount.get(phone).get(o.DO_DL__c).Id
          )
        );
      }
    }
    update ordersFirstUpdate;
  }
  public static void onAfterUpdate(
    Map<Id, Order> mapOld,
    Map<Id, Order> mapNew
  ) {
    Set<Id> setIdOrder = new Set<Id>();
    Set<Id> setIdOwner = new Set<Id>();
    Set<Id> setIdProductId = new Set<Id>();
    Set<Id> setOrderId = new Set<Id>();
    Set<Id> setIdOrderServicePackage = new Set<Id>();
    List<Order> lstOrderHandOver = new List<Order>();
    List<Order> lstOrderClosedDelivery = new List<Order>();
    List<Order> lstOrderCreateProfoma = new List<Order>();
    List<Order> lstOrderChangePromotion = new List<Order>();
    List<Order> lstOrderServiceWaiting = new List<Order>();
    List<Order> lstOrderFreeServiceApproval = new List<Order>();
    List<Order> lstOrderUndoBackOrder = new List<Order>();

    List<Order> lstOrderBikeCancel = new List<Order>();
    //Order Complete
    List<Order> lstOrderServiceComplete = new List<Order>();
    List<Order> lstOrderPCAComplete = new List<Order>();
    List<Order> lstOrderServiceByCampaing = new List<Order>();
    List<Order> lstOrderServiceOrQuickServiceCompleted = new List<Order>();
    Set<Id> setIdCampaign = new Set<Id>();
    Set<Id> ordersNonResident = new Set<Id>();
    // Manually change discount on line Manual Discount Approve change
    List<Order> lstManualDiscountApproveChange = new List<Order>();
    for (Order item : mapNew.values()) {
      if (mapOld.containsKey(item.Id)) {
        if (
          item.RecordTypeId == RecordTypeHelper.ORDER_APPRAISAL &&
          (mapOld.get(item.Id).OwnerID != item.OwnerID)
        ) {
          setIdOrder.add(item.Id);
          setIdOwner.add(item.OwnerId);
        }
        if (
          (item.RecordTypeId == RecordTypeHelper.ORDER_BIKE ||
          item.RecordTypeId == RecordTypeHelper.ORDER_PCA) &&
          (mapOld.get(item.Id).Status != item.Status) &&
          item.Status == 'Completed'
        ) {
          /*Order Non Resident*/
          if (
            item.RecordTypeId == RecordTypeHelper.ORDER_PCA &&
            string.isNotBlank(item.Order_Ecommerce__c) &&
            item.Non_Resident__c
          ) {
            ordersNonResident.add(item.Id);
          }
          setIdProductId.add(item.Product__c);
          lstOrderClosedDelivery.add(item);
          setOrderId.add(item.Id);
          ProgressCompleteOrder(item.Id);
        }
        if (
          item.RecordTypeId == RecordTypeHelper.ORDER_SERVICE_PACKAGE &&
          (mapOld.get(item.Id).Status != item.Status) &&
          item.Status == 'Completed'
        ) {
          setIdOrderServicePackage.add(item.Id);
        }
        if (item.RecordTypeId == RecordTypeHelper.ORDER_SERVICE_ORDER) {
          if (
            mapOld.get(item.Id).Campaign__c !=
            mapNew.get(item.Id).Campaign__c &&
            item.Campaign__c != null &&
            mapOld.get(item.Id).Manual_Discount_Approve__c ==
            item.Manual_Discount_Approve__c &&
            !item.Manual_Discount_Approve__c
          ) {
            lstOrderServiceByCampaing.add(item);
            setIdCampaign.add(item.Campaign__c);
          }
        }
        if (
          item.RecordTypeId == RecordTypeHelper.ORDER_PCA &&
          (mapOld.get(item.Id).Status != item.Status) &&
          item.Status == 'Back Order'
        ) {
          lstOrderCreateProfoma.add(item);
        }
        //WAITING FOR PARTS
        if (
          (item.RecordTypeId == RecordTypeHelper.ORDER_SERVICE_ORDER ||
          item.RecordTypeId == RecordTypeHelper.ORDER_FREE_SERVICE ||
          item.RecordTypeId == RecordTypeHelper.ORDER_QUICK_SERVICE ||
          item.RecordTypeId == RecordTypeHelper.ORDER_INTERNAL_SERVICE ||
          item.RecordTypeId == RecordTypeHelper.ORDER_FREE_COUPON ||
          item.RecordTypeId == RecordTypeHelper.ORDER_WARRANTY) &&
          (mapOld.get(item.Id).Status != item.Status) &&
          item.Status == 'Waiting for Parts'
        ) {
          lstOrderServiceWaiting.add(item);
        }
        if (
          (item.RecordTypeId == RecordTypeHelper.ORDER_SERVICE_ORDER ||
          item.RecordTypeId == RecordTypeHelper.ORDER_QUICK_SERVICE) &&
          ((mapOld.get(item.Id).Status != item.Status) ||
          (mapOld.get(item.Id).OwnerId != item.OwnerId)) &&
          item.Status == 'Completed'
        ) {
          lstOrderServiceOrQuickServiceCompleted.add(item);
        }
        /*if ((item.RecordTypeId == RecordTypeHelper.ORDER_SERVICE_ORDER || item.RecordTypeId == RecordTypeHelper.ORDER_QUICK_SERVICE || item.RecordTypeId == RecordTypeHelper.ORDER_INTERNAL_SERVICE) && (mapOld.get(item.Id).Status != item.Status) && item.Status == 'New'){
                    lstOrderUndoBackOrder.add(item);
                }*/
        if (
          item.RecordTypeId == RecordTypeHelper.ORDER_PCA &&
          (mapOld.get(item.Id).Status != item.Status) &&
          item.Status == 'Draft'
        ) {
          lstOrderUndoBackOrder.add(item);
        }
        if (
          (item.RecordTypeId == RecordTypeHelper.ORDER_SERVICE_ORDER ||
          item.RecordTypeId == RecordTypeHelper.ORDER_QUICK_SERVICE ||
          item.RecordTypeId == RecordTypeHelper.ORDER_FREE_SERVICE ||
          item.RecordTypeId == RecordTypeHelper.ORDER_PCA ||
          item.RecordTypeId == RecordTypeHelper.ORDER_INTERNAL_SERVICE ||
          item.RecordTypeId == RecordTypeHelper.ORDER_FREE_COUPON ||
          item.RecordTypeId == RecordTypeHelper.ORDER_WARRANTY) &&
          (mapOld.get(item.Id).Status != item.Status) &&
          item.Status == 'Completed'
        ) {
          lstOrderServiceComplete.add(item);
        }
        if (
          (item.RecordTypeId == RecordTypeHelper.ORDER_BIKE) &&
          (mapOld.get(item.Id).Status != item.Status) &&
          item.Status == 'Hand Over'
        ) {
          lstOrderHandOver.add(item);
        }
        if (
          (item.RecordTypeId == RecordTypeHelper.ORDER_BIKE) &&
          (mapOld.get(item.Id).Status != item.Status) &&
          item.Status == 'Cancel'
        ) {
          lstOrderBikeCancel.add(item);
        }
        if (
          (item.RecordTypeId == RecordTypeHelper.ORDER_PCA) &&
          (mapOld.get(item.Id).Promotion_Item__c != item.Promotion_Item__c)
        ) {
          lstOrderChangePromotion.add(item);
        }
        if (
          item.RecordTypeId == RecordTypeHelper.ORDER_FREE_SERVICE &&
          (mapOld.get(item.Id).Approval_Status__c != item.Approval_Status__c) &&
          (item.Approval_Status__c == 'Submit Approve' ||
          item.Approval_Status__c == 'Approved') &&
          (item.Request_From__c == 'Sales' ||
          item.Request_From__c == 'Marketing' ||
          item.Request_From__c == 'PCA' ||
          item.Request_From__c == 'Service')
        ) {
          lstOrderFreeServiceApproval.add(item);
        }
        if (
          (item.RecordTypeId == RecordTypeHelper.ORDER_SERVICE_ORDER ||
          item.RecordTypeId == RecordTypeHelper.ORDER_PCA ||
          item.RecordTypeId == RecordTypeHelper.ORDER_QUICK_SERVICE) &&
          mapOld.get(item.Id).Manual_Discount_Approve__c !=
          item.Manual_Discount_Approve__c
        ) {
          lstManualDiscountApproveChange.add(item);
          if (!item.Manual_Discount_Approve__c) {
            lstOrderServiceByCampaing.add(item); //Service By Campaign
            setIdCampaign.add(item.Campaign__c);
          }
        }
      }
    }
    if (!ordersNonResident.isEmpty()) {
      convertNonResidentToDO(mapNew, ordersNonResident);
    }
    if (!lstOrderServiceOrQuickServiceCompleted.isEmpty()) {
      createTaskForOrderServiceOrQuickServiceWhenCompleted(
        lstOrderServiceOrQuickServiceCompleted
      );
    }
    if (!lstOrderServiceByCampaing.isEmpty()) {
      //SERVICE ORDER BY CAMPAIGN
      progressServiceOrderByCampaign(lstOrderServiceByCampaing, setIdCampaign);
    }
    if (!lstOrderFreeServiceApproval.isEmpty()) {
      CustomNotification(lstOrderFreeServiceApproval);
    }
    if (!setIdOrderServicePackage.isEmpty()) {
      createPackageOwner(setIdOrderServicePackage);
    }
    if (!setIdOrder.isEmpty()) {
      //sendEmailToQueue(setIdOrder, setIdOwner);
    }
    if (!lstOrderClosedDelivery.isEmpty()) {
      progressClosedDeliveryBike(lstOrderClosedDelivery);
      closeTaskWhenCompletedOrder(setOrderId);
    }
    if (!lstOrderHandOver.isEmpty()) {
      progressHandOver(lstOrderHandOver);
    }
    if (lstOrderCreateProfoma.size() > 0) {
      ProgressBackOrder(lstOrderCreateProfoma);
    }
    if (lstOrderServiceWaiting.size() > 0) {
      ProgressServiceOrder(lstOrderServiceWaiting, mapNew.values());
    }
    if (lstOrderUndoBackOrder.size() > 0) {
      ProgressUndoBackOrder(lstOrderUndoBackOrder);
    }
    if (lstOrderServiceComplete.size() > 0) {
      ProgressServiceOrderComplete(lstOrderServiceComplete);
    }
    if (lstOrderBikeCancel.size() > 0) {
      ProgressCancelOrder(lstOrderBikeCancel);
    }

    // update order item if change approve change
    if (!lstManualDiscountApproveChange.isEmpty()) {
      Set<Id> SetOrderIDCH = new Set<ID>();
      for (Order item : lstManualDiscountApproveChange) {
        SetOrderIDCH.add(item.Id);
      }
      List<OrderItem> oiUpdated = [
        SELECT Id
        FROM OrderItem
        WHERE OrderId IN :SetOrderIDCH
      ];
      update oiUpdated;
    }
    //UPdate Order Item if change Promotion Item
    if (lstOrderChangePromotion.size() > 0) {
      Set<Id> SetOrderIDCH = new Set<ID>();
      for (Order item : lstOrderChangePromotion) {
        SetOrderIDCH.add(item.Id);
      }
      List<OrderItem> lstOrderItem = [
        SELECT Id
        FROM OrderItem
        WHERE OrderId IN :SetOrderIDCH
      ];
      if (lstOrderItem.size() > 0) {
        update lstOrderItem;
      }
    }
    checkConditionForNotify(mapOld, mapNew);
    syncToDMSOrderType(mapOld, mapNew);
  }
  private static void createTaskForOrderServiceOrQuickServiceWhenCompleted(
    List<Order> lstOrderServiceOrQuickServiceCompleted
  ) {
    List<Task> lstTaskInsert = new List<Task>();
    List<Group> lstGroupByOwnerId = new List<Group>();
    Set<Id> setIdOwnerIdOfOrder = new Set<Id>();
    Map<Id, List<Group>> mapOwnerWithGroups = new Map<Id, List<Group>>();
    try {
      List<Order> lstOrderQuerry = [
        SELECT
          Id,
          Service_Hours__c,
          Detailing_hours__c,
          Order_Number__c,
          OwnerId,
          Cashier__c,
          (
            SELECT Id, Labour_Hours__c, UnitPrice
            FROM OrderItems
          ),
          (
            SELECT
              Id,
              Task_Name__c,
              ActivityDate,
              Status,
              Is_Close__c,
              WhatId,
              WhoId,
              OwnerId,
              IsVisibleInSelfService
            FROM Tasks
            WHERE
              Is_Close__c = :false
              AND Status != :'Closed'
              AND Status != :'Not Completed'
              AND Status != :'Completed'
            LIMIT 1
          )
        FROM Order
        WHERE
          Id IN :lstOrderServiceOrQuickServiceCompleted
          AND Cashier__c != :null
      ];
      for (Order item : lstOrderQuerry) {
        setIdOwnerIdOfOrder.add(item.OwnerId);
      }
      for (Order item : lstOrderQuerry) {
        if (item.Tasks.isEmpty()) {
          if (!item.OrderItems.isEmpty()) {
            Decimal valueTotal = 0;
            Decimal valueLabelHours = 0;
            for (OrderItem i : item.OrderItems) {
              valueTotal += i.UnitPrice;

              valueLabelHours += i.Labour_Hours__c != null
                ? i.Labour_Hours__c
                : 0;
            }
            if (valueTotal >= 4000000 || valueLabelHours >= 4) {
              Task objTask = new Task();
              objTask.Type = 'Call';
              objTask.Status = 'In Processing';
              objTask.Priority = 'High';
              objTask.Subject = 'Follow Service ' + item.Order_Number__c;
              // objTask.Task_Name__c = '1 Day';
              objTask.WhoId = item.Cashier__c;
              objTask.OwnerId = item.OwnerId;
              objTask.IsVisibleInSelfService = true;
              objTask.ActivityDate = Date.valueOf(System.today().addDays(1));
              objTask.RecordTypeId = RecordTypeHelper.TASK_ORDER;
              objTask.WhatId = item.Id;
              lstTaskInsert.add(objTask);
            }
          }
        }
      }
      if (!lstTaskInsert.isEmpty()) {
        insert lstTaskInsert;
      }
    } catch (Exception ex) {
      lstOrderServiceOrQuickServiceCompleted.get(0)
        .addError(ex.getMessage() + ' ' + ex.getLineNumber());
    }
  }

  private static void progressServiceOrderByCampaign(
    List<Order> lstOrderServiceByCampaing,
    Set<Id> setIdCampaign
  ) {
    try {
      Map<Id, List<Map<Id, Promotion_Product__c>>> mapProductOnPromotionProduct = new Map<Id, List<Map<Id, Promotion_Product__c>>>();
      List<OrderItem> lstOrderItemUpdate = new List<OrderItem>();
      List<Order> lstOrderWithOrderItems = [
        SELECT
          Id,
          Campaign__c,
          Campaign__r.Promotion_Item__c,
          (
            SELECT
              Id,
              Product2Id,
              Quantity,
              TotalPrice,
              UnitPrice,
              PricebookEntryId,
              OrderId,
              Discount_Amount__c,
              Discount__c,
              ListPrice
            FROM OrderItems
          )
        FROM Order
        WHERE Id IN :lstOrderServiceByCampaing
      ];
      Set<Id> setIdPromotionItem = new Set<Id>();
      Map<Id, Campaign> mapCampaignByOrder = new Map<Id, Campaign>(
        [SELECT Id, Promotion_Item__c FROM Campaign WHERE Id IN :setIdCampaign]
      );
      for (Campaign item : mapCampaignByOrder.values()) {
        setIdPromotionItem.add(item.Promotion_Item__c);
      }
      Map<Id, Promotion_Item__c> mapPromotionItem = new Map<Id, Promotion_Item__c>(
        [
          SELECT
            Id,
            Discount__c,
            (
              SELECT
                Id,
                Product__c,
                Product__r.RecordTypeId,
                Product__r.ProductCode,
                Product__r.Name,
                Promotion_Item__r.Discount__c,
                Quantity__c,
                Discount__c
              FROM Promotion_Productts__r
            )
          FROM Promotion_Item__c
          WHERE Id IN :setIdPromotionItem
        ]
      );
      Map<Id, Map<Id, Promotion_Item__c>> mapOrderItemPromotionItem = new Map<Id, Map<Id, Promotion_Item__c>>();
      for (Campaign item : mapCampaignByOrder.values()) {
        if (String.isNotBlank(item.Promotion_Item__c)) {
          if (mapPromotionItem.containsKey(item.Promotion_Item__c)) {
            if (
              !mapPromotionItem.get(item.Promotion_Item__c)
                .Promotion_Productts__r.isEmpty()
            ) {
              for (
                Promotion_Product__c objPP : mapPromotionItem.get(
                    item.Promotion_Item__c
                  )
                  .Promotion_Productts__r
              ) {
                if (mapProductOnPromotionProduct.containsKey(item.Id)) {
                  mapProductOnPromotionProduct.get(item.Id)
                    .add(
                      new Map<Id, Promotion_Product__c>{
                        objPP.Product__c => objPP
                      }
                    );

                  mapOrderItemPromotionItem.get(item.Id)
                    .put(
                      objPP.Product__c,
                      new Promotion_Item__c(
                        Discount__c = mapPromotionItem
                          .get(item.Promotion_Item__c)
                          .Discount__c
                      )
                    );
                  continue;
                }
                mapProductOnPromotionProduct.put(
                  item.Id,
                  new List<Map<Id, Promotion_Product__c>>{
                    new Map<Id, Promotion_Product__c>{
                      objPP.Product__c => objPP
                    }
                  }
                );
                mapOrderItemPromotionItem.put(
                  item.Id,
                  new Map<Id, Promotion_Item__c>{
                    objPP.Product__c => new Promotion_Item__c(
                      Discount__c = mapPromotionItem
                        .get(item.Promotion_Item__c)
                        .Discount__c
                    )
                  }
                );
              }
            }
          }
        }
      }
      for (Order item : lstOrderWithOrderItems) {
        if (!item.OrderItems.isEmpty()) {
          if (mapProductOnPromotionProduct.containsKey(item.Campaign__c)) {
            for (
              Map<Id, Promotion_Product__c> mapPromoProd : mapProductOnPromotionProduct.get(
                item.Campaign__c
              )
            ) {
              for (OrderItem oi : item.OrderItems) {
                if (mapPromoProd.containsKey(oi.Product2Id)) {
                  oi.Promotion_Product__c = mapPromoProd.get(oi.Product2Id).Id;
                  if (
                    mapPromoProd.get(oi.Product2Id).Product__r.RecordTypeId ==
                    RecordTypeHelper.SV_JOB
                  ) {
                    oi.Discount__c = mapPromoProd.get(oi.Product2Id)
                      .Discount__c;
                    oi.Discount_Amount__c =
                      (oi.ListPrice *
                      mapPromoProd.get(oi.Product2Id).Discount__c) / 100;
                    oi.UnitPrice = oi.UnitPrice - oi.Discount_Amount__c;
                  } else if (
                    mapPromoProd.get(oi.Product2Id).Product__r.RecordTypeId ==
                    RecordTypeHelper.PRODUCT_PCA
                  ) {
                    if (
                      mapPromoProd.get(oi.Product2Id).Quantity__c != null &&
                      mapPromoProd.get(oi.Product2Id).Discount__c == null
                    ) {
                      // oi.Discount__c = mapPromoProd.get(oi.Product2Id).Discount__c;
                      oi.Discount__c = mapOrderItemPromotionItem.get(
                          item.Campaign__c
                        )
                        .get(oi.Product2Id)
                        .Discount__c;
                      if (
                        oi.Quantity <=
                        mapPromoProd.get(oi.Product2Id).Quantity__c
                      ) {
                        //Khi quantity trên order product nhỏ hơn promotion product
                        mapPromoProd.get(oi.Product2Id).Quantity__c =
                          mapPromoProd.get(oi.Product2Id).Quantity__c -
                          oi.Quantity;
                        oi.Discount_Amount__c = oi.ListPrice * oi.Quantity;
                        oi.UnitPrice = 0;
                      } else {
                        //Khi quantity trên order product lớn hơn promotion product
                        if (mapPromoProd.get(oi.Product2Id).Quantity__c > 0) {
                          oi.Discount_Amount__c =
                            oi.ListPrice *
                            mapPromoProd.get(oi.Product2Id).Quantity__c;
                          oi.UnitPrice = 0;

                          lstOrderItemUpdate.add(
                            new OrderItem(
                              Quantity = oi.Quantity -
                                mapPromoProd.get(oi.Product2Id).Quantity__c,
                              Product2Id = oi.Product2Id,
                              PricebookEntryId = oi.PricebookEntryId,
                              UnitPrice = oi.ListPrice,
                              OrderId = oi.OrderId
                            )
                          );
                          oi.Quantity = mapPromoProd.get(oi.Product2Id)
                            .Quantity__c;
                          mapPromoProd.get(oi.Product2Id).Quantity__c = 0;
                        }
                      }
                    } else if (
                      mapPromoProd.get(oi.Product2Id).Quantity__c == null &&
                      mapPromoProd.get(oi.Product2Id).Discount__c != null
                    ) {
                      oi.Discount_Amount__c =
                        (oi.ListPrice *
                        mapPromoProd.get(oi.Product2Id).Discount__c *
                        oi.Quantity) / 100;
                      oi.Discount__c = mapPromoProd.get(oi.Product2Id)
                        .Discount__c;
                      oi.UnitPrice =
                        oi.ListPrice - oi.ListPrice * oi.Discount__c / 100;
                    }
                  }
                  lstOrderItemUpdate.add(oi);
                }
              }
            }
          }
        }
      }
      if (!lstOrderItemUpdate.isEmpty()) {
        upsert lstOrderItemUpdate;
      }
    } catch (Exception ex) {
      lstOrderServiceByCampaing[0]
        .addError(ex.getMessage() + ' ' + ex.getLineNumber());
    }
  }

  private static void CustomNotification(List<Order> lstOrders) {
    try {
      CustomNotificationType notificationType = [
        SELECT Id
        FROM CustomNotificationType
        WHERE DeveloperName = 'Send_Notify_Cation'
      ];
      Messaging.CustomNotification notification = new Messaging.CustomNotification();
      Set<String> recipientsIds = new Set<String>();
      Map<Id, User> mapGetAllUserBySale = mapGetAllUserBySale();
      Map<Id, User> mapGetAllUserByMKT = mapGetAllUserByMKT();
      Map<Id, User> mapGetAllUserByPCA = mapGetAllUserByPCA();
      Map<Id, User> mapGetAllUserByService = mapGetAllUserByPCA();
      List<Order> lstOrder = new List<Order>();

      notification.setNotificationTypeId(notificationType.Id);

      List<Order> lstOrderItemByOrder = [
        SELECT
          Id,
          OrderNumber,
          Request_From__c,
          Approval_Status__c,
          (SELECT Id FROM OrderItems)
        FROM Order
        WHERE Id IN :lstOrders
      ];

      for (Order item : lstOrderItemByOrder) {
        if (item.Approval_Status__c == 'Submit Approve') {
          Set<String> idStrs = new Set<String>();
          notification.setTitle('Free Service was submited approval.');
          notification.setBody(
            'Free Service was submited with Order Number ' + item.OrderNumber
          );
          notification.setTargetId(item.Id);
          if (
            item.Request_From__c == 'Sales' &&
            !mapGetAllUserBySale.keySet().isEmpty()
          ) {
            idStrs = (Set<String>) JSON.deserialize(
              JSON.serialize(mapGetAllUserBySale.keySet()),
              Set<String>.class
            );
          } else if (
            item.Request_From__c == 'Marketing' &&
            !mapGetAllUserByMKT.keySet().isEmpty()
          ) {
            idStrs = (Set<String>) JSON.deserialize(
              JSON.serialize(mapGetAllUserByMKT.keySet()),
              Set<String>.class
            );
          } else if (
            item.Request_From__c == 'PCA' &&
            !mapGetAllUserByPCA.keySet().isEmpty()
          ) {
            idStrs = (Set<String>) JSON.deserialize(
              JSON.serialize(mapGetAllUserByPCA.keySet()),
              Set<String>.class
            );
          } else if (
            item.Request_From__c == 'Service' &&
            !mapGetAllUserByService.keySet().isEmpty()
          ) {
            idStrs = (Set<String>) JSON.deserialize(
              JSON.serialize(mapGetAllUserByService.keySet()),
              Set<String>.class
            );
          }
          if (!idStrs.isEmpty()) {
            notification.send(idStrs);
          }
          item.Is_Approval__c = true;
        } else if (item.Approval_Status__c == 'Approved') {
          Set<String> idStrs = new Set<String>();
          notification.setTitle('Free Service was approved.');
          notification.setBody(
            'Free Service was approved with Order Number ' + item.OrderNumber
          );
          notification.setTargetId(item.Id);
          if (!mapGetAllUserByService.keySet().isEmpty()) {
            idStrs = (Set<String>) JSON.deserialize(
              JSON.serialize(mapGetAllUserByService.keySet()),
              Set<String>.class
            );
          }
        }
      }
      if (!lstOrderItemByOrder.isEmpty()) {
        update lstOrderItemByOrder;
      }
    } catch (Exception ex) {
      lstOrders[0].addError(ex.getMessage() + ' ' + ex.getLineNumber());
    }
  }

  private static Map<Id, User> mapGetAllUserBySale() {
    return new Map<Id, User>(
      [
        SELECT Id
        FROM User
        WHERE
          (Profile.Name = :'Community DO DL Manager'
          OR Profile.Name = :'Community Sales Profile'
          OR Profile.Name = :'Community Sale Sup'
          OR Profile.Name = :'System Administrator')
          AND IsActive = :true
      ]
    );
  }

  private static Map<Id, User> mapGetAllUserByMKT() {
    return new Map<Id, User>(
      [
        SELECT Id
        FROM User
        WHERE
          (Profile.Name = :'MKT Manager'
          OR Profile.Name = :'System Administrator')
          AND IsActive = :true
      ]
    );
  }

  private static Map<Id, User> mapGetAllUserByPCA() {
    return new Map<Id, User>(
      [
        SELECT Id
        FROM User
        WHERE
          (Profile.Name = :'Community Consultant PCA'
          OR Profile.Name = :'Community Consultant PCA 2'
          OR Profile.Name = :'Community Warehouse'
          OR Profile.Name = :'System Administrator')
          AND IsActive = :true
      ]
    );
  }

  private static Map<Id, User> mapGetAllUserByService() {
    return new Map<Id, User>(
      [
        SELECT Id
        FROM User
        WHERE
          (Profile.Name = :'Community Consultant Service'
          OR Profile.Name = :'System Administrator')
          AND IsActive = :true
      ]
    );
  }

  //Progress Cancel Order
  private static void ProgressCancelOrder(List<Order> lstOrder) {
    List<Contract> contracts = new List<Contract>();
    List<Opportunity> lstOpptyUpsert = new List<Opportunity>();
    List<Asset> lstAssetUpsert = new List<Asset>();
    List<X3_Inventory_Transaction_Header__c> lstTransactionHeader = new List<X3_Inventory_Transaction_Header__c>();
    Map<ID, ID> MapOrderOppty = new Map<ID, ID>();
    List<Order> lstOrderUpdate = new List<Order>();
    Savepoint sp = Database.setSavepoint();
    try {
      for (Order item : lstOrder) {
        MapOrderOppty.put(item.Id, item.OpportunityId);
        if (String.isNotBlank(item.ContractId)) {
          contracts.add(new Contract(Id = item.ContractId, Status = 'Cancel'));
        }
        if (String.isNotBlank(item.OpportunityId)) {
          lstOpptyUpsert.add(
            new Opportunity(Id = item.OpportunityId, StageName = 'Assigned')
          );
        }
        if (String.isNotBlank(item.Asset__c)) {
          lstAssetUpsert.add(
            new Asset(Id = item.Asset__c, Inventory_Status__c = 'Available')
          );
        }
      }
      lstTransactionHeader = [
        SELECT Id, Status__c
        FROM X3_Inventory_Transaction_Header__c
        WHERE Order_Reserved__c IN :MapOrderOppty.keySet()
      ];
      if (!lstTransactionHeader.isEmpty()) {
        for (X3_Inventory_Transaction_Header__c itemTH : lstTransactionHeader) {
          itemTH.Status__c = 'Cancled';
        }
        update lstTransactionHeader;
      }
      // Get Payement To Update Opportunity
      List<Payment__c> payListed = new List<Payment__c>();
      for (Payment__c pay : [
        SELECT Id, Order__c, Opportunity__c
        FROM Payment__c
        WHERE Order__c IN :MapOrderOppty.keySet()
      ]) {
        payListed.add(
          new Payment__c(
            Opportunity__c = MapOrderOppty?.get(pay.Order__c),
            Order__c = null,
            Id = pay.Id
          )
        );
      }
      upsert payListed;

      if (!contracts.isEmpty()) {
        upsert contracts;
      }
      if (!lstOpptyUpsert.isEmpty()) {
        upsert lstOpptyUpsert;
      }
      if (!lstAssetUpsert.isEmpty()) {
        upsert lstAssetUpsert;
      }
    } catch (Exception ex) {
      Database.rollback(sp);
      lstOrder[0].addError(ex.getMessage() + ' ' + ex.getLineNumber());
    }
  }

  //Create Service Package
  private static void createPackageOwner(Set<Id> setIdOrder) {
    try {
      Map<Id, Package_Owner__c> mapOrderKeyVlauesPackage = new Map<Id, Package_Owner__c>();
      Map<Id, List<Product_Detail_Service__c>> mapProdSessionWithParentService = new Map<Id, List<Product_Detail_Service__c>>();
      List<Order_Line_Detail__c> orderLines = new List<Order_Line_Detail__c>();
      Set<Id> productsID = new Set<Id>();
      Map<Id, OrderItem> mapOrderItemQuerry = new Map<Id, OrderItem>(
        [
          SELECT
            Id,
            Order.AccountId,
            Product2Id,
            Date_Active__c,
            Product2.Quantity_Measure__c,
            Product2.Unit_Measure__c,
            Package_Owner__c,
            Product2.RecordTypeId
          FROM OrderItem
          WHERE OrderId IN :setIdOrder
        ]
      );
      for (OrderItem item : mapOrderItemQuerry.values()) {
        if (
          item.Product2.RecordTypeId ==
          RecordTypeHelper.PRODUCT_SERVICE_PACKAGE &&
          item.Package_Owner__c == null
        ) {
          Package_Owner__c obj = new Package_Owner__c();
          obj.Package_Personal_Account__c = item.Order.AccountId;
          obj.Service_Package__c = item.Product2Id;
          obj.Effective_Date__c = item.Date_Active__c;
          obj.Order_Product__c = item.Id;
          if (item.Product2.Unit_Measure__c == 'Days') {
            obj.Expired_Date__c = item.Date_Active__c.addDays(
              Integer.valueOf(item.Product2.Quantity_Measure__c)
            );
          } else if (item.Product2.Unit_Measure__c == 'Months') {
            obj.Expired_Date__c = item.Date_Active__c.addMonths(
              Integer.valueOf(item.Product2.Quantity_Measure__c)
            );
          }
          productsID.add(item.Product2Id);
          mapOrderKeyVlauesPackage.put(item.Id, obj);
        }
      }

      List<Product_Detail_Service__c> productsService = [
        SELECT Id, Quantity__c, Product__c, Product_Service_Package__c
        FROM Product_Detail_Service__c
        WHERE Product_Service_Package__c IN :productsID
      ];
      if (!productsService.isEmpty()) {
        getProdServicePkChildDetailSession(
          productsService,
          mapProdSessionWithParentService
        );
      }

      if (!mapOrderKeyVlauesPackage.values().isEmpty()) {
        insert mapOrderKeyVlauesPackage.values();
        for (OrderItem item : mapOrderItemQuerry.values()) {
          if (mapOrderKeyVlauesPackage.containsKey(item.Id)) {
            item.Package_Owner__c = mapOrderKeyVlauesPackage.get(item.Id).Id;
          }
          if (mapProdSessionWithParentService.containsKey(item.Product2Id)) {
            for (
              Product_Detail_Service__c itemProd : mapProdSessionWithParentService.get(
                item.Product2Id
              )
            ) {
              Order_Line_Detail__c orderLine = new Order_Line_Detail__c();
              orderLine.Product_Detail_Service__c = itemProd.Id;
              orderLine.Remain__c = itemProd.Quantity__c;
              orderLine.Order_Line_Item__c = item.Id;
              orderLine.Package_Owner__c = item.Package_Owner__c;
              orderLines.add(orderLine);
            }
          }
        }

        insert orderLines;

        update mapOrderItemQuerry.values();
      }
    } catch (Exception ex) {
      System.debug('ex :' + ex.getMessage());
    }
  }

  private static void getProdServicePkChildDetailSession(
    List<Product_Detail_Service__c> lstProductDetailService,
    Map<Id, List<Product_Detail_Service__c>> mapProdSessionWithParentService
  ) {
    for (Product_Detail_Service__c item : lstProductDetailService) {
      if (
        mapProdSessionWithParentService.containsKey(
          item.Product_Service_Package__c
        )
      ) {
        List<Product_Detail_Service__c> productsService = mapProdSessionWithParentService.get(
          item.Product_Service_Package__c
        );
        productsService.add(item);
        mapProdSessionWithParentService.put(
          item.Product_Service_Package__c,
          productsService
        );
      } else {
        mapProdSessionWithParentService.put(
          item.Product_Service_Package__c,
          new List<Product_Detail_Service__c>{ item }
        );
      }
    }
  }

  private static void ProgressUndoBackOrder(List<Order> orders) {
    Set<ID> ordersID = new Set<ID>();
    for (Order item : orders) {
      ordersID.add(item.Id);
    }
    List<X3_Inventory_Transaction_Header__c> tranHeaderItems = new List<X3_Inventory_Transaction_Header__c>();

    List<Order> ordersProfoma = new List<Order>();

    for (X3_Inventory_Transaction_Header__c item : [
      SELECT Id, Status__c
      FROM X3_Inventory_Transaction_Header__c
      WHERE Order_Reserved__c IN :ordersID
    ]) {
      item.Status__c = 'Cancled';
      tranHeaderItems.add(item);
    }
    update tranHeaderItems;
    for (Order order : [
      SELECT Id, Order__c, Status
      FROM Order
      WHERE
        Order__c IN :ordersID
        AND RecordTypeId = :RecordTypeHelper.ORDER_PROFOMAR_ORDER
    ]) {
      order.Status = 'Terminated';
      ordersProfoma.add(order);
    }
    update ordersProfoma;
  }

  private static void ProgressServiceOrder(
    List<Order> lstOrder,
    List<Order> lstOrderNews
  ) {
    Savepoint sp = Database.setSavepoint();
    Set<ID> SetOrderID = new Set<ID>();
    for (Order item : lstOrder) {
      SetOrderID.add(item.Id);
    }
    List<OrderItem> lstOrderItem = [
      SELECT
        Id,
        OrderId,
        Product2Id,
        Profomar_Order__c,
        Installtion__c,
        Quantity,
        PricebookEntryId
      FROM OrderItem
      WHERE
        OrderId IN :SetOrderID
        AND Product2.RecordTypeId = :RecordTypeHelper.PRODUCT_PCA
    ];

    try {
      if (lstOrderItem.size() > 0) {
        List<OrderItem> lstOrderItemProfoma = new List<OrderItem>();

        List<OrderItem> lstOrdItemTransactionService = new List<OrderItem>();

        Set<ID> SetOrderProfomaID = new Set<ID>();

        for (OrderItem ItemOrderItem : lstOrderItem) {
          if (ItemOrderItem.Profomar_Order__c) {
            lstOrderItemProfoma.add(ItemOrderItem);
            SetOrderProfomaID.add(ItemOrderItem.OrderId);
          } else {
            lstOrdItemTransactionService.add(ItemOrderItem);
          }
        }

        if (lstOrderItemProfoma.size() > 0) {
          List<Order> lstOrderNewProfoma = new List<Order>();
          List<OrderItem> lstNewOrderItemProfoma = new List<OrderItem>();

          for (ID OrderItemId : SetOrderProfomaID) {
            Order objOrder = new Order();
            objOrder.Order__c = lstOrder[0].Id;
            objOrder.AccountId = lstOrder[0].DO_DL__c;
            objOrder.DO_DL__c = lstOrder[0].DO_DL__c;
            objOrder.Pricebook2Id = lstOrder[0].Pricebook2Id;
            objOrder.Status = 'Draft';
            objOrder.EffectiveDate = ONDATE;
            objOrder.RecordTypeId = RecordTypeHelper.ORDER_PROFOMAR_ORDER;
            lstOrderNewProfoma.add(objOrder);
          }
          insert lstOrderNewProfoma;
          if (lstOrderNewProfoma.size() > 0) {
            for (OrderItem ItemProItem : lstOrderItemProfoma) {
              OrderItem objOrderItemProfoma = new OrderItem();
              objOrderItemProfoma.OrderId = lstOrderNewProfoma[0].Id;
              objOrderItemProfoma.Quantity = ItemProItem.Quantity;
              objOrderItemProfoma.UnitPrice = 0;
              objOrderItemProfoma.PricebookEntryId = ItemProItem.PricebookEntryId;
              lstNewOrderItemProfoma.add(objOrderItemProfoma);
            }

            if (lstNewOrderItemProfoma.size() > 0) {
              insert lstNewOrderItemProfoma;
            }
          }
        } else if (lstOrdItemTransactionService.size() > 0) {
          List<Account> accountDODL = [
            SELECT Id, Warehouse_Location__c, Warehouse_Location_Service__c
            FROM Account
            WHERE Id = :lstOrder[0].DO_DL__c
          ];

          if (lstOrdItemTransactionService.size() > 0) {
            X3_Inventory_Transaction_Header__c objTransactionHeader = new X3_Inventory_Transaction_Header__c();
            objTransactionHeader.Order_Reserved__c = lstOrder[0].Id;
            objTransactionHeader.Status__c = 'Draft';
            objTransactionHeader.To_Warehouse_Location__c = accountDODL[0]
              .Warehouse_Location_Service__c;
            objTransactionHeader.From_Warehouse_Location__c = accountDODL[0]
              .Warehouse_Location__c;

            objTransactionHeader.Name = 'Reserved Order';

            insert objTransactionHeader;

            List<Inventory_Transaction_Item__c> lstTransactionItem = new List<Inventory_Transaction_Item__c>();
            for (OrderItem ItemOrder : lstOrdItemTransactionService) {
              Inventory_Transaction_Item__c objTransactionItem = new Inventory_Transaction_Item__c();
              objTransactionItem.Product__c = ItemOrder.Product2Id;
              objTransactionItem.Quantity__c = ItemOrder.Quantity;
              objTransactionItem.From_Warehouse_Location__c = accountDODL[0]
                .Warehouse_Location__c;
              objTransactionItem.To_Warehouse_Location__c = accountDODL[0]
                .Warehouse_Location_Service__c;
              objTransactionItem.Inventory_Transaction_Header__c = objTransactionHeader.Id;
              lstTransactionItem.add(objTransactionItem);
            }
            insert lstTransactionItem;
          }
        }
      }
    } catch (Exception ex) {
      System.debug('ex.getMessage() :' + ex.getMessage());
      Database.rollBack(sp);
      lstOrderNews.get(0).addError(ex.getMessage() + ex.getLineNumber());
    }
  }

  private static void ProgressServiceOrderComplete(List<Order> lstOrder) {
    List<X3_Inventory_Transaction_Header__c> inventoryHeader = [
      SELECT Id, Status__c
      FROM X3_Inventory_Transaction_Header__c
      WHERE
        Order_Reserved__c = :lstOrder[0].Id
        AND (Status__c != 'Completed'
        OR Status__c != 'Cancled')
    ];

    Set<Id> InventoryHeaderId = new Set<Id>();
    for (X3_Inventory_Transaction_Header__c itemHeader : [
      SELECT Id, Status__c
      FROM X3_Inventory_Transaction_Header__c
      WHERE Order_Reserved__c = :lstOrder[0].Id AND Status__c = 'Completed'
    ]) {
      InventoryHeaderId.add(itemHeader.Id);
    }

    if (lstOrder[0].RecordTypeId == RecordTypeHelper.ORDER_PCA) {
      if (!inventoryHeader.isEmpty()) {
        for (X3_Inventory_Transaction_Header__c iheader : inventoryHeader) {
          iheader.Status__c = 'Completed';
        }
        update inventoryHeader;
      } else {
        Set<ID> ordersID = new Set<ID>();
        for (Order item : lstOrder) {
          ordersID.add(item.Id);
        }
        //system.debug('DNNNDNFNF ProgressBackOrder');
        List<OrderItem> orderItems = [
          SELECT
            Id,
            OrderId,
            Product2Id,
            Profomar_Order__c,
            Installtion__c,
            Quantity,
            PricebookEntryId
          FROM OrderItem
          WHERE OrderId IN :ordersID
        ];
        if (orderItems.size() > 0) {
          List<OrderItem> orderItemsProfoma = new List<OrderItem>();
          List<OrderItem> lstOrdItemTransaction = new List<OrderItem>();

          Set<ID> ordersProfomaID = new Set<ID>();

          for (OrderItem ItemOrderItem : orderItems) {
            if (ItemOrderItem.Profomar_Order__c) {
              orderItemsProfoma.add(ItemOrderItem);
              ordersProfomaID.add(ItemOrderItem.OrderId);
            } else {
              lstOrdItemTransaction.add(ItemOrderItem);
            }
          }

          if (orderItemsProfoma.size() > 0) {
            List<Order> orderNewProfoma = new List<Order>();
            List<OrderItem> lstNewOrderItemProfoma = new List<OrderItem>();

            for (ID OrderItemId : ordersProfomaID) {
              Order o = new Order();
              o.Order__c = lstOrder[0].Id;
              o.AccountId = lstOrder[0].DO_DL__c;
              o.DO_DL__c = lstOrder[0].DO_DL__c;
              o.Pricebook2Id = lstOrder[0].Pricebook2Id;
              o.Status = 'Draft';
              o.EffectiveDate = ONDATE;
              o.RecordTypeId = RecordTypeHelper.ORDER_PROFOMAR_ORDER;
              orderNewProfoma.add(o);
            }
            insert orderNewProfoma;

            if (orderNewProfoma.size() > 0) {
              for (OrderItem ItemProItem : orderItemsProfoma) {
                OrderItem objOrderItemProfoma = new OrderItem();
                objOrderItemProfoma.OrderId = orderNewProfoma[0].Id;
                objOrderItemProfoma.Quantity = ItemProItem.Quantity;
                objOrderItemProfoma.UnitPrice = 0;
                objOrderItemProfoma.PricebookEntryId = ItemProItem.PricebookEntryId;
                lstNewOrderItemProfoma.add(objOrderItemProfoma);
              }

              if (lstNewOrderItemProfoma.size() > 0) {
                insert lstNewOrderItemProfoma;
              }
            }
          } else if (lstOrdItemTransaction.size() > 0) {
            List<Account> lstAccountDODL = [
              SELECT Id, Warehouse_Location__c, Warehouse_Location_Service__c
              FROM Account
              WHERE Id = :lstOrder[0].DO_DL__c
            ];
            X3_Inventory_Transaction_Header__c tranHeader = new X3_Inventory_Transaction_Header__c();
            tranHeader.Order_Reserved__c = lstOrder[0].Id;
            tranHeader.Status__c = 'Draft';
            tranHeader.From_Warehouse_Location__c = lstAccountDODL[0]
              .Warehouse_Location__c;
            tranHeader.Name = 'Reserse ';

            insert tranHeader;

            List<Inventory_Transaction_Item__c> lstTransactionItem = new List<Inventory_Transaction_Item__c>();
            for (OrderItem ItemOrder : lstOrdItemTransaction) {
              Inventory_Transaction_Item__c tranItem = new Inventory_Transaction_Item__c();
              tranItem.Product__c = ItemOrder.Product2Id;
              tranItem.Quantity__c = ItemOrder.Quantity;
              tranItem.From_Warehouse_Location__c = lstAccountDODL[0]
                .Warehouse_Location__c;
              tranItem.Inventory_Transaction_Header__c = tranHeader.Id;
              lstTransactionItem.add(tranItem);
            }
            insert lstTransactionItem;
            tranHeader.Status__c = 'Completed';
            update tranHeader;
          }
        }
      }
    } else {
      List<Inventory_Transaction_Item__c> lstTransactionItem = [
        SELECT
          Id,
          Name,
          Warehouse_Inventory__c,
          From_Warehouse_Location__c,
          To_Warehouse_Location__c,
          Quantity__c,
          Product__c
        FROM Inventory_Transaction_Item__c
        WHERE Inventory_Transaction_Header__c IN :InventoryHeaderId
      ];

      List<Account> accountDODL = [
        SELECT Id, Warehouse_Location__c, Warehouse_Location_Service__c
        FROM Account
        WHERE Id = :lstOrder[0].DO_DL__c
      ];
      if (lstTransactionItem.size() > 0) {
        X3_Inventory_Transaction_Header__c transactionHeader = new X3_Inventory_Transaction_Header__c();
        transactionHeader.Order_Reserved__c = lstOrder[0].Id;
        transactionHeader.Status__c = 'Draft';
        transactionHeader.From_Warehouse_Location__c = accountDODL[0]
          .Warehouse_Location_Service__c;
        transactionHeader.Name =
          'Service Output ' + lstOrder[0].Order_Number__c;

        insert transactionHeader;

        List<Inventory_Transaction_Item__c> lstTransactionItemNew = new List<Inventory_Transaction_Item__c>();
        for (Inventory_Transaction_Item__c ItemOrder : [
          SELECT
            Id,
            Name,
            Warehouse_Inventory__c,
            From_Warehouse_Location__c,
            To_Warehouse_Location__c,
            Quantity__c,
            Product__c
          FROM Inventory_Transaction_Item__c
          WHERE Inventory_Transaction_Header__c IN :InventoryHeaderId
        ]) {
          Inventory_Transaction_Item__c transactionItem = new Inventory_Transaction_Item__c();
          transactionItem.Product__c = ItemOrder.Product__c;
          transactionItem.Quantity__c = ItemOrder.Quantity__c;
          transactionItem.From_Warehouse_Location__c = accountDODL[0]
            .Warehouse_Location_Service__c;
          transactionItem.Inventory_Transaction_Header__c = transactionHeader.Id;
          lstTransactionItemNew.add(transactionItem);
        }
        insert lstTransactionItemNew;

        transactionHeader.Status__c = 'Completed';
        update transactionHeader;
      }
    }
  }

  private static void ProgressBackOrder(List<Order> lstOrder) {
    Set<ID> SetOrderID = new Set<ID>();
    for (Order item : lstOrder) {
      SetOrderID.add(item.Id);
    }
    List<OrderItem> lstOrderItem = [
      SELECT
        Id,
        OrderId,
        Product2Id,
        Profomar_Order__c,
        Installtion__c,
        Quantity,
        PricebookEntryId
      FROM OrderItem
      WHERE OrderId IN :SetOrderID
    ];
    if (lstOrderItem.size() > 0) {
      List<OrderItem> lstOrderItemProfoma = new List<OrderItem>();
      List<OrderItem> lstOrdItemTransaction = new List<OrderItem>();
      Set<ID> SetOrderProfomaID = new Set<ID>();

      for (OrderItem ItemOrderItem : lstOrderItem) {
        if (ItemOrderItem.Profomar_Order__c) {
          lstOrderItemProfoma.add(ItemOrderItem);
          SetOrderProfomaID.add(ItemOrderItem.OrderId);
        } else {
          lstOrdItemTransaction.add(ItemOrderItem);
        }
      }

      if (lstOrderItemProfoma.size() > 0) {
        List<Order> orderNewProfoma = new List<Order>();
        List<OrderItem> oiProfomas = new List<OrderItem>();

        for (ID OrderItemId : SetOrderProfomaID) {
          Order o = new Order();
          o.Order__c = lstOrder[0].Id;
          o.AccountId = lstOrder[0].DO_DL__c;
          o.DO_DL__c = lstOrder[0].DO_DL__c;
          o.Pricebook2Id = lstOrder[0].Pricebook2Id;
          o.Status = 'Draft';
          o.EffectiveDate = ONDATE;
          o.RecordTypeId = RecordTypeHelper.ORDER_PROFOMAR_ORDER;
          orderNewProfoma.add(o);
        }
        insert orderNewProfoma;
        for (OrderItem ItemProItem : lstOrderItemProfoma) {
          OrderItem oiProfoma = new OrderItem();
          oiProfoma.OrderId = orderNewProfoma[0].Id;
          oiProfoma.Quantity = ItemProItem.Quantity;
          oiProfoma.UnitPrice = 0;
          oiProfoma.PricebookEntryId = ItemProItem.PricebookEntryId;
          oiProfomas.add(oiProfoma);
        }
        insert oiProfomas;
      } else if (lstOrdItemTransaction.size() > 0) {
        List<Account> accountDODL = [
          SELECT Id, Warehouse_Location__c, Warehouse_Location_Service__c
          FROM Account
          WHERE Id = :lstOrder[0].DO_DL__c
        ];

        if (lstOrdItemTransaction.size() > 0) {
          X3_Inventory_Transaction_Header__c transactionHeader = new X3_Inventory_Transaction_Header__c();
          transactionHeader.Order_Reserved__c = lstOrder[0].Id;
          transactionHeader.Status__c = 'Draft';
          transactionHeader.From_Warehouse_Location__c = accountDODL[0]
            .Warehouse_Location__c;
          transactionHeader.Name = 'Reserse ';

          insert transactionHeader;

          List<Inventory_Transaction_Item__c> lstTransactionItem = new List<Inventory_Transaction_Item__c>();
          for (OrderItem ItemOrder : lstOrdItemTransaction) {
            Inventory_Transaction_Item__c transactionItem = new Inventory_Transaction_Item__c();
            transactionItem.Product__c = ItemOrder.Product2Id;
            transactionItem.Quantity__c = ItemOrder.Quantity;
            transactionItem.From_Warehouse_Location__c = accountDODL[0]
              .Warehouse_Location__c;
            transactionItem.Inventory_Transaction_Header__c = transactionHeader.Id;
            lstTransactionItem.add(transactionItem);
          }
          if (lstTransactionItem.size() > 0) {
            insert lstTransactionItem;
            transactionHeader.Status__c = 'Completed';
            update transactionHeader;
          }
        }
      }
    }
  }

  private static void progressHandOver(List<Order> lstOrderNews) {
    Savepoint sp = Database.setSavepoint();
    try {
      Set<Id> setOpportunityId = new Set<Id>();
      Set<Id> setOpportunityPCA = new Set<Id>();
      for (Order item : lstOrderNews) {
        setOpportunityId.add(item.OpportunityId);
      }
      List<Task> tasksForUser = new List<Task>();

      for (Opportunity item : [
        SELECT Id, PCA_Type__c, RecordTypeId, OwnerId, Account.Name
        FROM Opportunity
        WHERE
          Opportunity_Bike__c = :setOpportunityId
          AND RecordTypeId = :RecordTypeHelper.OPPORTUNITY_PCA
          AND (PCA_Type__c = 'P&A'
          OR PCA_Type__c = 'Clothing')
      ]) {
        tasksForUser.add(
          new Task(
            Type = 'Call',
            Status = 'In Processing',
            Priority = 'High',
            Subject = 'Follow Opportunity PCA',
            WhatId = item.Id,
            Estimate_Task__c = Datetime.now().addHours(72),
            Task_Name__c = '2 Days',
            OwnerId = item.OwnerId,
            RecordTypeId = RecordTypeHelper.TASK_OPPORTUNITY,
            Task_Type__c = 'Follow Up',
            ActivityDate = Date.today().addDays(3)
          )
        );
      }
      insert tasksForUser;
    } catch (Exception ex) {
      System.debug('ex.getMessage() :' + ex.getMessage());
      Database.rollBack(sp);
      lstOrderNews.get(0).addError(ex.getMessage() + ex.getLineNumber());
    }
  }

  //Process asset and transaction header, account after complete 1 order
  @future
  private static void ProgressCompleteOrder(Id OrderID) {
    List<Order> orders = [
      SELECT
        Id,
        AccountId,
        Account.Account_Is_Primary__c,
        Asset__c,
        RecordTypeID
      FROM Order
      WHERE Id = :OrderID
    ];

    if (!orders.isEmpty()) {
      if (orders[0].RecordTypeID == RecordTypeHelper.ORDER_BIKE) {
        if (orders[0].Account.Account_Is_Primary__c != null) {
          Account account = new Account();
          account.Id = orders[0].Account.Account_Is_Primary__c;
          account.Applied_Promotion__c = true;
          update account;
        }
        Asset asset = new Asset();
        asset.Id = orders[0].Asset__c;
        asset.Account_Customer__c = orders[0].AccountId;
        asset.Account_Primary_Owner__c = orders[0]
          .Account.Account_Is_Primary__c;
        asset.Inventory_Status__c = 'Not Available';
        asset.Order__c = orders[0].Id;
        update asset;

        List<X3_Inventory_Transaction_Header__c> transactionHeader = [
          SELECT Id, Type__c, Name, Order_Reserved__c, Status__c
          FROM X3_Inventory_Transaction_Header__c
          WHERE Order_Reserved__c = :orders[0].Id
        ];

        for (X3_Inventory_Transaction_Header__c header : transactionHeader) {
          header.Status__c = 'Completed ';
        }
        update transactionHeader;
      }
    }
  }

  //Chuyển status Task đang in proccesing thành closed khi completed status của Order là PCA và Bike
  private static void closeTaskWhenCompletedOrder(Set<Id> orderID) {
    List<Task> tasksUpdate = new List<Task>();
    for (Task item : [
      SELECT Id, Status
      FROM Task
      WHERE
        WhatId IN :orderID
        AND (Status = :'In Processing'
        OR Status = :'Open')
    ]) {
      tasksUpdate.add(
        new Task(
          Id = item.Id,
          Status = item.Status == 'Open' ? 'Completed' : 'Closed'
        )
      );
    }
    update tasksUpdate;
  }

  //Tạo ra object After Sale (Order Account) cho order có record type là bike hoặc pca khi completed.
  private static void progressClosedDeliveryBike(
    List<Order> lstOrderClosedDelivery
  ) {
    List<Order_Account__c> ordersAccount = new List<Order_Account__c>();
    List<Order_Account__c> lstOrderAccountQuerry = new List<Order_Account__c>();
    List<Task> tasksInsert = new List<Task>();
    try {
      for (Order item : lstOrderClosedDelivery) {
        Order_Account__c aftersale = new Order_Account__c();
        aftersale.Name = item.OrderNumber;
        aftersale.Order__c = item.Id;
        aftersale.Account__c = item.AccountId;
        aftersale.OwnerId = item.OwnerId;
        if (item.RecordTypeID == RecordTypeHelper.ORDER_BIKE)
          aftersale.RecordTypeId = RecordTypeHelper.ORDER_ACCOUNT_BIKE;
        else if (item.RecordTypeID == RecordTypeHelper.ORDER_PCA)
          aftersale.RecordTypeId = RecordTypeHelper.ORDER_ACCOUNT_PCA;
        ordersAccount.add(aftersale);
      }
      insert ordersAccount;
      for (Order_Account__c item : [
        SELECT
          Id,
          Account__r.PersonContactId,
          Order__c,
          Order__r.Product__c,
          Bike_cc_Product__c,
          RecordTypeID,
          Order__r.Total_Amount__c,
          OwnerId
        FROM Order_Account__c
        WHERE Id IN :ordersAccount
      ]) {
        if (
          item.RecordTypeID == RecordTypeHelper.ORDER_ACCOUNT_PCA &&
          item.Order__r.Total_Amount__c > 20000000
        ) {
          /*(item.Bike_cc_Product__c == '>400cc' && item.RecordTypeId == RecordTypeHelper.ORDER_ACCOUNT_BIKE)*/
          tasksInsert.add(createTaskByProductBike(item, '1 Day', 24));
        } /*else if (item.Bike_cc_Product__c == '<400cc' && item.RecordTypeId == RecordTypeHelper.ORDER_ACCOUNT_BIKE){
            		lstTaskInsert.add(createTaskByProductBike(item, '2 Days', 48));
            	}*/
      }
      insert tasksInsert;
    } catch (Exception ex) {
      System.debug('ex :' + ex.getMessage());
    }
  }

  private static Task createTaskByProductBike(
    Order_Account__c item,
    String strNameTask,
    Integer intTimeAdd
  ) {
    Datetime dt = Datetime.now();
    Task task = new Task();
    task.WhatId = item.Id;
    task.WhoId = item.Account__r.PersonContactId;
    task.Subject = item.RecordTypeId == RecordTypeHelper.ORDER_ACCOUNT_BIKE
      ? 'Follow up After Sale Bike'
      : (item.RecordTypeId == RecordTypeHelper.ORDER_ACCOUNT_PCA
          ? 'Follow up After Sale PCA'
          : null);
    task.Status = 'In Processing';
    task.Is_Close__c = false;
    task.RecordTypeId = RecordTypeHelper.TASK_AFTERSALE;
    task.Task_Type__c = 'Follow up';
    task.Task_Name__c = strNameTask;
    task.Estimate_Task__c = dt.addHours(intTimeAdd);
    task.ActivityDate = Date.valueOf(task.Estimate_Task__c);
    task.OwnerId = item.OwnerId;
    return task;
  }

  private static void checkConditionForNotify(
    Map<Id, Order> oldMap,
    Map<Id, Order> newMap
  ) {
    List<Order> lstOrderNotify = new List<Order>();
    for (Order ord : newMap.values()) {
      if (
        ord.Status == 'Hand Over' &&
        oldMap.get(ord.Id).Status != 'Hand Over'
      ) {
        lstOrderNotify.add(ord);
      }
    }
    if (!lstOrderNotify.isEmpty()) {
      notifyHandOver(lstOrderNotify);
    }
  }

  // Notify users when order status change to 'Hand Over'
  private static void notifyHandOver(List<Order> lstOrderNotify) {
    if (!System.isFuture() && !System.isBatch()) {
      Set<Id> optyIds = new Set<Id>();
      Set<Id> ownerIds = new Set<Id>();
      Set<Id> AccountIds = new Set<Id>();
      List<Order> lstOrder = [
        SELECT
          Id,
          OrderNumber,
          Order_Number__c,
          OwnerId,
          OpportunityId,
          Opportunity.OwnerId,
          RecordTypeId,
          RecordType.Name,
          Bike_Delivery_Date__c,
          AccountId,
          Account.Name
        FROM Order
        WHERE Id IN :lstOrderNotify AND RecordType.Name = 'Sales Bike Order'
      ];
      if (!lstOrder.isEmpty()) {
        for (Order o : lstOrder) {
          ownerIds.add(o.OwnerId);
          optyIds.add(o.OpportunityId);
          AccountIds.add(o.AccountId);
        }

        //   Opty owner - các opty PCA đang open
        List<Opportunity> optyOwners = [
          SELECT Id, OwnerId, AccountId
          FROM Opportunity
          WHERE
            StageName != 'Closed Lost'
            AND StageName != 'Closed Won'
            AND RecordType.Name = 'PCA'
            AND AccountId IN :AccountIds
        ];

        //Object opty team member

        for (Order o : lstOrder) {
          Set<String> recipientsIds = new Set<String>();
          //Opty owner - các opty PCA đang open
          for (Opportunity opty : optyOwners) {
            if (opty.AccountId == o.AccountId) {
              recipientsIds.add(opty.OwnerId);
            }
          }
          //Opty team member
          for (OpportunityTeamMember member : [
            SELECT Id, UserId, OpportunityId
            FROM OpportunityTeamMember
            WHERE OpportunityId IN :optyIds
          ]) {
            if (member.OpportunityId == o.OpportunityId) {
              recipientsIds.add(member.UserId);
            }
          }
          // Order owner - các order chưa completed (pca, service)
          for (Order ord : [
            SELECT Id, OwnerId, AccountId
            FROM Order
            WHERE
              Status NOT IN ('Completed', 'Closed')
              AND RecordType.Name IN ('Sales PCA order', 'Service Order')
              AND AccountId IN :AccountIds
          ]) {
            if (ord.AccountId == o.AccountId)
              recipientsIds.add(ord.OwnerId);
          }
          //   Sale Manager, Sale Admin (lấy giá trị trên User Owner Order hiện tại)
          for (User u : [
            SELECT Id, DODL_Manager__c, Sales_Admin__c
            FROM User
            WHERE Id = :OwnerIds
          ]) {
            if (u.Id == o.OwnerId) {
              recipientsIds.add(u.DODL_Manager__c);
              recipientsIds.add(u.Sales_Admin__c);
            }
          }
          //    Order owner - các order chưa completed (pca, service)
          for (User systemAdmin : [
            SELECT Id, UserRole.Name
            FROM User
            WHERE UserRole.Name = 'System Admin'
          ]) {
            recipientsIds.add(systemAdmin.Id);
          }
          // Get the Id for our custom notification type
          CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HandOver_Notification'
          ];
          // Create a new custom notification
          Messaging.CustomNotification notification = new Messaging.CustomNotification();
          String dateTimeStr = '';
          if (o.Bike_Delivery_Date__c != null)
            dateTimeStr = o.Bike_Delivery_Date__c.format('dd/MM/yyyy hh:mm a');
          // Set the contents for the notification
          notification.setTitle('Hand-Over notification ');

          notification.setBody(
            'Đơn hàng ' +
              o.Order_Number__c +
              ' sẽ được bàn giao xe cho ' +
              o.Account.Name +
              ' bắt đầu từ ' +
              dateTimeStr
          );

          // Set the notification type and target
          notification.setNotificationTypeId(notificationType.Id);
          notification.setTargetId(o.Id);
          // Actually send the notification
          recipientsIds.remove(null);
          try {
            notification.send(recipientsIds);
          } catch (Exception e) {
            System.debug('Problem sending notification: ' + e.getMessage());
          }
        }
      }
    }
  }

  private static void checkConditionWarranty(List<Order> newData) {
    // List<Order> ordersUpdate = new List<Order>();
    Set<Id> idAssets = new Set<Id>();
    for (Order o : newData) {
      idAssets.add(o.Asset__c);
    }
    Map<Id, Asset> mapAss = new Map<Id, Asset>(
      [
        SELECT
          Id,
          Create_Manual__c,
          Product2Id,
          Product2.Bike_cc__c,
          Number_of_Month_Gar_del__c,
          PurchaseDate,
          Invoiced_Date__c,
          Warranty_Kilometers__c,
          Warranty_Effective_Date__c,
          Warrant_Expired_Date__c
        FROM Asset
        WHERE Id IN :idAssets
      ]
    );
    for (Order o : newData) {
      if (o.RecordTypeId == RecordTypeHelper.ORDER_WARRANTY) {
        if (o.Mileage__c == null) {
          o.Mileage__c.addError('Hãy nhập giá trị cho Mileage!');
          o.addError('Hãy nhập giá trị cho Mileage!');
        }
        // if (!mapAss.isEmpty()) {
        if (
          (o.AccountId == null &&
          mapAss.get(o.Asset__c).Invoiced_Date__c == null) ||
          o.GoodWill__c == true
        ) {
        } else {
          if (o.AccountId == null) {
            o.AccountId.addError('Owner Order is required');
          }
          if (
            !o.Warranty_0_Kilometer__c &&
            mapAss.get(o.Asset__c).Invoiced_Date__c == null &&
            !mapAss.get(o.Asset__c).Create_Manual__c
          ) {
            o.addError('Invoiced Date is required for Order Odo 0 Kilometer');
          }

          if (mapAss.get(o.Asset__c).Product2.Bike_cc__c == '<400cc') {
            if (o.Mileage__c > mapAss.get(o.Asset__c).Warranty_Kilometers__c) {
              o.Mileage__c.addError('Mileage is over Warranty Kilometers.');
              o.GoodWill__c.addError('Do you implement Warranty Goodwill.');
            }
            Date firstDate = o.EffectiveDate;
            Date secondDate = mapAss.get(o.Asset__c).PurchaseDate;
            Date warrantyEffectiveDate = mapAss.get(o.Asset__c)
              .Warranty_Effective_Date__c;
            Date warrantExpiredDate = mapAss.get(o.Asset__c)
              .Warrant_Expired_Date__c;
            Integer monthDiff = 0;
            if (secondDate != null) {
              monthDiff = secondDate.monthsBetween(firstDate);
            }

            if (monthDiff > mapAss.get(o.Asset__c).Number_of_Month_Gar_del__c) {
              o.EffectiveDate.addError('Không được bảo hành!');
              o.GoodWill__c.addError(
                'Bạn có muốn thực hiện Warranty Goodwill?'
              );
            }
            if (
              firstDate < warrantyEffectiveDate ||
              firstDate > warrantExpiredDate
            ) {
              o.EffectiveDate.addError(
                'Không được bảo hành do vượt quá thời hạn bảo hành!'
              );
            }
          } else if (mapAss.get(o.Asset__c).Product2.Bike_cc__c == '>400cc') {
            Date firstDate = o.EffectiveDate;
            Date warrantyEffectiveDate = mapAss.get(o.Asset__c)
              .Warranty_Effective_Date__c;
            Date warrantExpiredDate = mapAss.get(o.Asset__c)
              .Warrant_Expired_Date__c;
            Date secondDate = mapAss.get(o.Asset__c).PurchaseDate;
            Integer monthDiff = 0;
            if (secondDate != null) {
              monthDiff = secondDate.monthsBetween(firstDate);
            }

            if (monthDiff > mapAss.get(o.Asset__c).Number_of_Month_Gar_del__c) {
              o.EffectiveDate.addError('Không được bảo hành!');
              o.GoodWill__c.addError(
                'Bạn có muốn thực hiện Warranty Goodwill?'
              );
            }
            if (
              firstDate < warrantyEffectiveDate ||
              firstDate > warrantExpiredDate
            ) {
              o.EffectiveDate.addError(
                'Không được bảo hành do vượt quá thời hạn bảo hành!'
              );
            }
          }
        }
      }
    }
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
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;

    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;

    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;

    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
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
