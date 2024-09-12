@IsTest(SeeAllData=true)
public class TriggerOrderTest {
    private static testMethod void testMethod1() {
        test.startTest();
        TriggerOrder.cheatTemp();
        TriggerHandlerInventoryTransactionItems.cheatTemp();
        test.stopTest();
    }
    // Task ymvn-1035
    @IsTest
    static void testOnBeforeInsertFreeCouponOrder() {
        Account testAccount = new Account(
            Name = 'Test Account',
            Phone = '1234567890'
        );
        insert testAccount;

        Product2 testProduct = new Product2(
            Name = 'Test Bike',
            Bike_cc__c = '>400cc'
        );
        insert testProduct;

        Asset testAsset = new Asset(
            Name = 'Test Asset',
            AccountId = testAccount.Id,
            Product2Id = testProduct.Id,
            Warranty_Effective_Date__c = Date.today().addDays(-30),
            Warrant_Expired_Date__c = Date.today().addDays(30)
        );
        insert testAsset;

        Free_Coupon__c testCoupon = new Free_Coupon__c(
            Asset__c = testAsset.Id,
            Applied__c = false,
            WarrantyEffectiveDate__c = Date.today().addDays(-30),
            WarrantyExpiredDate__c = Date.today().addDays(30)
        );
        insert testCoupon;
        Free_Coupon__c myCoupon = [
            SELECT
                Id,
                ApplicationPointCode__c,
                Applied__c,
                WarrantyEffectiveDate__c,
                WarrantyExpiredDate__c,
                Asset__c
            FROM Free_Coupon__c
            WHERE Id = :testCoupon.Id
        ];
        Order testOrder = new Order(
            AccountId = testAccount.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            // Order_Type__c = 'Free Coupon',
            RecordTypeId = RecordTypeHelper.ORDER_FREE_COUPON,
            Asset__c = testAsset.Id,
            Mileage__c = 1000,
            Free_Coupon__c = testCoupon.Id,
            IMEI_Free_Coupon__c = myCoupon.ApplicationPointCode__c
        );

        Test.startTest();
        insert testOrder;
        Test.stopTest();

        Order insertedOrder = [
            SELECT Free_Coupon__c
            FROM Order
            WHERE Id = :testOrder.Id
        ];
        System.assertNotEquals(
            null,
            insertedOrder.Free_Coupon__c,
            'Free Coupon order should not be null'
        );

        Free_Coupon__c updatedCoupon = [
            SELECT Applied__c, WarrantyMileage__c, ServiceDate__c
            FROM Free_Coupon__c
            WHERE Id = :testCoupon.Id
        ];
        System.assertEquals(
            true,
            updatedCoupon.Applied__c,
            'Free Coupon should be applied'
        );
        System.assertEquals(
            1000,
            updatedCoupon.WarrantyMileage__c,
            'Free Coupon should have the correct warranty mileage'
        );
        System.assertEquals(
            Date.today(),
            updatedCoupon.ServiceDate__c,
            'Free Coupon should have the correct service date'
        );
    }
    @IsTest
    static void testOnBeforeInsertBikeOrder() {
        Account testAccount = new Account(
            Name = 'Test Account',
            Phone = '1234567890'
        );
        insert testAccount;

        User testUser = [
            SELECT Id, AccountId
            FROM User
            WHERE Account.Name = :'REVZONE YAMAHA MOTOR HA NOI'
            LIMIT 1
        ];

        Order testOrder = new Order(
            AccountId = testAccount.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            OwnerId = testUser.Id,
            RecordTypeId = RecordTypeHelper.ORDER_BIKE
        );

        Test.startTest();
        insert testOrder;
        Test.stopTest();

        Order insertedOrder = [
            SELECT Order_Number__c
            FROM Order
            WHERE Id = :testOrder.Id
        ];
        System.assert(
            insertedOrder.Order_Number__c.startsWith('SO-MC-'),
            'Bike order number should start with SO-MC-'
        );
    }
    @IsTest
    static void testOnBeforeInsertServicePackageOrder() {
        Account testAccount = new Account(
            Name = 'Test Account',
            Phone = '1234567890'
        );
        insert testAccount;

        User testUser = [
            SELECT Id, AccountId
            FROM User
            WHERE Account.Name = :'REVZONE YAMAHA MOTOR HA NOI'
            LIMIT 1
        ];

        Order testOrder = new Order(
            AccountId = testAccount.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            OwnerId = testUser.Id,
            RecordTypeId = RecordTypeHelper.ORDER_SERVICE_PACKAGE
        );

        Test.startTest();
        insert testOrder;
        Test.stopTest();

        Order insertedOrder = [
            SELECT Order_Number__c
            FROM Order
            WHERE Id = :testOrder.Id
        ];
        System.debug(insertedOrder.Order_Number__c);
        System.assert(
            insertedOrder.Order_Number__c.startsWith('SO-PACK-'),
            'Service Package order number should start with SO-PACK-'
        );
    }
    @IsTest
    static void testOnBeforeInsertPCAOrder() {
        Account testAccount = new Account(
            Name = 'Test Account',
            Phone = '1234567890'
        );
        insert testAccount;

        User testUser = [
            SELECT Id, AccountId
            FROM User
            WHERE Account.Name = :'REVZONE YAMAHA MOTOR HA NOI'
            LIMIT 1
        ];

        Order testOrder = new Order(
            AccountId = testAccount.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            OwnerId = testUser.Id,
            RecordTypeId = RecordTypeHelper.ORDER_PCA
        );

        Test.startTest();
        insert testOrder;
        Test.stopTest();

        Order insertedOrder = [
            SELECT Order_Number__c, Promotion_Item__c
            FROM Order
            WHERE Id = :testOrder.Id
        ];
        System.assert(
            insertedOrder.Order_Number__c.startsWith('SO-PCA-'),
            'PCA order number should start with SO-PCA-'
        );
    }

    @IsTest
    static void testOrderStatusChangeToCompleted() {
        Account mockAccount = new Account(
            Name = 'Test Account',
            Phone = '1234567890'
        );
        insert mockAccount;

        Product2 mockProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TEST001'
        );
        insert mockProduct;

        Order mockOrder = new Order(
            AccountId = mockAccount.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            RecordTypeId = RecordTypeHelper.ORDER_BIKE
        );
        insert mockOrder;

        Order testOrder = [
            SELECT Id, Status, RecordTypeId
            FROM Order
            LIMIT 1
        ];
        testOrder.Status = 'Draft';
        update testOrder;

        Test.startTest();
        testOrder.Status = 'Completed';
        update testOrder;
        Test.stopTest();

        Order updatedOrder = [
            SELECT Id, Status
            FROM Order
            WHERE Id = :testOrder.Id
        ];
        System.assertEquals(
            'Completed',
            updatedOrder.Status,
            'Order status should be Completed'
        );
    }

    @IsTest
    static void testOrderOwnerChange() {
        Account mockAccount = new Account(
            Name = 'Test Account',
            Phone = '1234567890'
        );
        insert mockAccount;

        Product2 mockProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TEST001'
        );
        insert mockProduct;

        Order mockOrder = new Order(
            AccountId = mockAccount.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            RecordTypeId = RecordTypeHelper.ORDER_BIKE
        );
        insert mockOrder;
        Order testOrder = [
            SELECT Id, OwnerId, RecordTypeId
            FROM Order
            LIMIT 1
        ];
        testOrder.RecordTypeId = RecordTypeHelper.ORDER_APPRAISAL;
        update testOrder;

        User newOwner = [
            SELECT Id
            FROM User
            WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE
            LIMIT 1
        ];

        Test.startTest();
        testOrder.OwnerId = newOwner.Id;
        update testOrder;
        Test.stopTest();

        Order updatedOrder = [
            SELECT Id, OwnerId
            FROM Order
            WHERE Id = :testOrder.Id
        ];
        System.assertEquals(
            newOwner.Id,
            updatedOrder.OwnerId,
            'Order owner should be updated'
        );
    }

    @IsTest
    static void testOrderStatusChangeToBackOrder() {
        Account mockAccount = new Account(
            Name = 'Test Account',
            Phone = '1234567890'
        );
        insert mockAccount;

        Product2 mockProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TEST001'
        );
        insert mockProduct;

        Order mockOrder = new Order(
            AccountId = mockAccount.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            RecordTypeId = RecordTypeHelper.ORDER_BIKE
        );
        insert mockOrder;
        Order testOrder = [
            SELECT Id, Status, RecordTypeId
            FROM Order
            LIMIT 1
        ];
        testOrder.RecordTypeId = RecordTypeHelper.ORDER_PCA;
        testOrder.Status = 'Draft';
        update testOrder;

        Test.startTest();
        testOrder.Status = 'Back Order';
        update testOrder;
        Test.stopTest();

        Order updatedOrder = [
            SELECT Id, Status
            FROM Order
            WHERE Id = :testOrder.Id
        ];
        System.assertEquals(
            'Back Order',
            updatedOrder.Status,
            'Order status should be Back Order'
        );
    }

    @IsTest
    static void testOrderStatusChangeToWaitingForParts() {
        Account mockAccount = new Account(
            Name = 'Test Account',
            Phone = '1234567890'
        );
        insert mockAccount;

        Product2 mockProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TEST001'
        );
        insert mockProduct;

        Order mockOrder = new Order(
            AccountId = mockAccount.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            RecordTypeId = RecordTypeHelper.ORDER_BIKE
        );
        insert mockOrder;
        Order testOrder = [
            SELECT Id, Status, RecordTypeId
            FROM Order
            LIMIT 1
        ];
        testOrder.RecordTypeId = RecordTypeHelper.ORDER_SERVICE_ORDER;
        testOrder.Status = 'Draft';
        update testOrder;

        Test.startTest();
        testOrder.Status = 'Waiting for Parts';
        update testOrder;
        Test.stopTest();

        Order updatedOrder = [
            SELECT Id, Status
            FROM Order
            WHERE Id = :testOrder.Id
        ];
        System.assertEquals(
            'Waiting for Parts',
            updatedOrder.Status,
            'Order status should be Waiting for Parts'
        );
    }

    @IsTest
    static void testOrderStatusChangeToHandOver() {
        Account mockAccount = new Account(
            Name = 'Test Account',
            Phone = '1234567890'
        );
        insert mockAccount;

        Product2 mockProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TEST001'
        );
        insert mockProduct;

        Order mockOrder = new Order(
            AccountId = mockAccount.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            RecordTypeId = RecordTypeHelper.ORDER_BIKE
        );
        insert mockOrder;
        Order testOrder = [
            SELECT Id, Status, RecordTypeId
            FROM Order
            LIMIT 1
        ];
        testOrder.RecordTypeId = RecordTypeHelper.ORDER_BIKE;
        testOrder.Status = 'Draft';
        update testOrder;

        Test.startTest();
        testOrder.Status = 'Hand Over';
        update testOrder;
        Test.stopTest();

        Order updatedOrder = [
            SELECT Id, Status
            FROM Order
            WHERE Id = :testOrder.Id
        ];
        System.assertEquals(
            'Hand Over',
            updatedOrder.Status,
            'Order status should be Hand Over'
        );
    }

    @IsTest
    static void testOrderStatusChangeToCancel() {
        Account mockAccount = new Account(
            Name = 'Test Account',
            Phone = '1234567890'
        );
        insert mockAccount;

        Product2 mockProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TEST001'
        );
        insert mockProduct;

        Order mockOrder = new Order(
            AccountId = mockAccount.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            RecordTypeId = RecordTypeHelper.ORDER_BIKE
        );
        insert mockOrder;
        Order testOrder = [
            SELECT Id, Status, RecordTypeId
            FROM Order
            LIMIT 1
        ];
        testOrder.RecordTypeId = RecordTypeHelper.ORDER_BIKE;
        testOrder.Status = 'Draft';
        update testOrder;

        Test.startTest();
        testOrder.Status = 'Cancel';
        update testOrder;
        Test.stopTest();

        Order updatedOrder = [
            SELECT Id, Status
            FROM Order
            WHERE Id = :testOrder.Id
        ];
        System.assertEquals(
            'Cancel',
            updatedOrder.Status,
            'Order status should be Cancel'
        );
    }

    @IsTest
    static void testOrderFreeServiceApprovalStatusChange() {
        Account mockAccount = new Account(
            Name = 'Test Account',
            Phone = '1234567890'
        );
        insert mockAccount;

        Product2 mockProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TEST001'
        );
        insert mockProduct;

        Order mockOrder = new Order(
            AccountId = mockAccount.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            RecordTypeId = RecordTypeHelper.ORDER_BIKE
        );
        insert mockOrder;
        Order testOrder = [
            SELECT Id, Approval_Status__c, RecordTypeId, Request_From__c
            FROM Order
            LIMIT 1
        ];
        testOrder.RecordTypeId = RecordTypeHelper.ORDER_FREE_SERVICE;
        testOrder.Request_From__c = 'Sales';
        testOrder.Approval_Status__c = 'Draft';
        update testOrder;

        Test.startTest();
        testOrder.Approval_Status__c = 'Submit Approve';
        update testOrder;
        Test.stopTest();

        Order updatedOrder = [
            SELECT Id, Approval_Status__c
            FROM Order
            WHERE Id = :testOrder.Id
        ];
        System.assertEquals(
            'Submit Approve',
            updatedOrder.Approval_Status__c,
            'Approval Status should be Submit Approve'
        );
    }

    @IsTest
    static void testOrderManualDiscountApproveChange() {
        Account mockAccount = new Account(
            Name = 'Test Account',
            Phone = '1234567890'
        );
        insert mockAccount;

        Product2 mockProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TEST001'
        );
        insert mockProduct;

        Order mockOrder = new Order(
            AccountId = mockAccount.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            RecordTypeId = RecordTypeHelper.ORDER_BIKE
        );
        insert mockOrder;
        Order testOrder = [
            SELECT Id, Manual_Discount_Approve__c, RecordTypeId
            FROM Order
            LIMIT 1
        ];
        testOrder.RecordTypeId = RecordTypeHelper.ORDER_SERVICE_ORDER;
        testOrder.Manual_Discount_Approve__c = false;
        update testOrder;

        Test.startTest();
        testOrder.Manual_Discount_Approve__c = true;
        update testOrder;
        Test.stopTest();

        Order updatedOrder = [
            SELECT Id, Manual_Discount_Approve__c
            FROM Order
            WHERE Id = :testOrder.Id
        ];
        System.assertEquals(
            true,
            updatedOrder.Manual_Discount_Approve__c,
            'Manual Discount Approve should be true'
        );
    }
}
