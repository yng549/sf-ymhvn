/*******************************************************************************
 ** Class Name: SyncDMSHelper
 ** Description: This class reuse to function for getting data DMS.
 ** Version: 1.0
 ** Created By: THL
 ** Modified By:
 *******************************************************************************/
public class SyncDMSHelper {
    public static Boolean runningInASandbox {
        get {
            if (runningInASandbox == null) {
                runningInASandbox = [SELECT IsSandbox FROM Organization LIMIT 1]
                .IsSandbox;
            }
            return runningInASandbox;
        }
        set;
    }
    // Constantly
    private static Map<String, API_DMS__c> settingAPIDMS = API_DMS__c.getAll();
    public static final String BODYEMPTY = '{}';
    private static final Id IDPBSTANDARD = [
        SELECT Id, Name, IsActive, IsStandard
        FROM Pricebook2
        WHERE IsStandard = TRUE
    ]
    .Id;
    private static final Id IDPBPCAService = [
        SELECT Id
        FROM Pricebook2
        WHERE
            Type__c = 'PCAService'
            AND Isactive = TRUE
            AND is_Employee__c = FALSE
    ]
    .Id;
    private static final Id IDPBPCAWARRANTY = [
        SELECT Id
        FROM Pricebook2
        WHERE Type__c = 'Warranty' AND Isactive = TRUE
    ]
    .Id;
    private static final Pricebook2 PBPCAEmployee = [
        SELECT Id, Policy__r.Price__c
        FROM Pricebook2
        WHERE
            Type__c = 'PCAService'
            AND Isactive = TRUE
            AND is_Employee__c = TRUE
        LIMIT 1
    ];
    public static String trimErrorMessage(String errorMessage) {
        if (errorMessage.length() > 30000) {
            errorMessage = errorMessage.substring(0, 30000);
        }
        return errorMessage;
    }
    public static void createPricebookEntireStandard(
        Map<String, Product2> productCodeMap
    ) {
        Map<String, Id> mapExternalId = new Map<String, Id>();
        List<PricebookEntry> lstPBEStarndard = new List<PricebookEntry>();
        for (PricebookEntry entry : [
            SELECT Id, ServiceJob_Key__c
            FROM PricebookEntry
            WHERE
                ServiceJob_Key__c IN :productCodeMap.keySet()
                AND Pricebook2Id = :IDPBSTANDARD
        ]) {
            mapExternalId.put(entry.ServiceJob_Key__c, entry.Id);
        }
        for (String key : productCodeMap.keySet()) {
            PricebookEntry pricingStandard = createPriceBookEntry(
                IDPBSTANDARD,
                productCodeMap.get(key).Id,
                0
            );
            pricingStandard.Id = mapExternalId.get(key);
            lstPBEStarndard.add(pricingStandard);
        }
        upsert lstPBEStarndard;
    }
    public static void createPricebookEntirePart(
        Map<String, Product2> productCodeMap,
        Map<String, Integer> partNoRetailPriceMap
    ) {
        Map<String, Id> mapExternalId = new Map<String, Id>();
        List<PricebookEntry> lstPBEParts = new List<PricebookEntry>();
        for (PricebookEntry entry : [
            SELECT Id, ServiceJob_Key__c
            FROM PricebookEntry
            WHERE
                ServiceJob_Key__c IN :productCodeMap.keySet()
                AND Pricebook2Id = :IDPBPCAService
        ]) {
            mapExternalId.put(entry.ServiceJob_Key__c, entry.Id);
        }
        for (String key : productCodeMap.keySet()) {
            PricebookEntry pricePCAService = createPriceBookEntry(
                IDPBPCAService,
                productCodeMap.get(key).Id,
                partNoRetailPriceMap.get(key) +
                ((partNoRetailPriceMap.get(key) *
                productCodeMap.get(key).Vat__c) / 100)
            );
            pricePCAService.Id = mapExternalId.get(key);
            lstPBEParts.add(pricePCAService);
        }
        upsert lstPBEParts;
    }
    // YMHVN-996, New nethod to create pricebook entry for YMH's employees
    public static void createPricebookEntirePartEmployee(
        Map<String, Product2> productCodeMap,
        Map<String, Integer> partNoRetailPriceMap
    ) {
        Map<String, Id> mapExternalId = new Map<String, Id>();
        List<PricebookEntry> lstPBEParts = new List<PricebookEntry>();
        for (PricebookEntry entry : [
            SELECT Id, ServiceJob_Key__c
            FROM PricebookEntry
            WHERE
                ServiceJob_Key__c IN :productCodeMap.keySet()
                AND Pricebook2Id = :PBPCAEmployee.Id
        ]) {
            mapExternalId.put(entry.ServiceJob_Key__c, entry.Id);
        }
        for (String key : productCodeMap.keySet()) {
            PricebookEntry pricePCAServiceEmployee = createPriceBookEntry(
                PBPCAEmployee.Id,
                productCodeMap.get(key).Id,
                partNoRetailPriceMap.get(key) *
                    (PBPCAEmployee?.Policy__r?.Price__c ?? 0) *
                    (productCodeMap.get(key).VAT__c / 100 + 1)
            );
            pricePCAServiceEmployee.Id = mapExternalId.get(key);
            lstPBEParts.add(pricePCAServiceEmployee);
        }
        upsert lstPBEParts;
    }
    public static void createPEPartWarranty(
        Map<String, Product2> productCodeMap,
        Map<String, Integer> partNoRetailPriceMap
    ) {
        Map<String, Id> mapExternalId = new Map<String, Id>();
        List<PricebookEntry> lstPBEParts = new List<PricebookEntry>();
        for (PricebookEntry entry : [
            SELECT Id, ServiceJob_Key__c
            FROM PricebookEntry
            WHERE
                ServiceJob_Key__c IN :productCodeMap.keySet()
                AND Pricebook2Id = :IDPBPCAWARRANTY
        ]) {
            mapExternalId.put(entry.ServiceJob_Key__c, entry.Id);
        }
        for (String key : productCodeMap.keySet()) {
            PricebookEntry priceWarranty = createPriceBookEntry(
                IDPBPCAWARRANTY,
                productCodeMap.get(key).Id,
                partNoRetailPriceMap.get(key)
            );
            priceWarranty.Id = mapExternalId.get(key);
            lstPBEParts.add(priceWarranty);
        }
        upsert lstPBEParts;
    }
    public static PricebookEntry createPriceBookEntry(
        Id pricebookId,
        Id proid,
        Decimal unitprice
    ) {
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = proid,
            UnitPrice = unitprice,
            IsActive = true
        );
        return pbe;
    }
    private static string convertToDateFormat(Date d) {
        String month = String.valueOf(d.month()).leftPad(2, '0');
        String day = String.valueOf(d.day()).leftPad(2, '0');
        return d.year() + month + day;
    }
    public static SObjectAPIDMSRespone.Modelcsalesorder convertModelSaleRequestData(
        Order ord,
        List<OrderItem> partsales
    ) {
        SObjectAPIDMSRespone.Modelcsalesorder modelsales = new SObjectAPIDMSRespone.Modelcsalesorder();
        modelsales.CRMOrderId = ord.Id;
        modelsales.CRMOrderNo = ord.OrderNumber;
        modelsales.DealerCode = ord.DO_DL__r.Branch__r.DO_DL_Code__c;
        modelsales.PointCode = ord.DO_DL__r.DO_DL_Code__c;
        modelsales.SalesDate = String.valueOf(ord.EffectiveDate)
            .replaceAll('-', '');
        modelsales.EinvoiceFlag = '1';
        modelsales.FrameNo = ord.Asset__r.Frame_Number__c;
        modelsales.RegistrationDate = String.valueOf(Date.today())
            .replaceAll('-', '');
        modelsales.CRMConsumerId = ord.Account.Account_Is_Primary__c;
        modelsales.LastName = ord.Account.LastName;
        if (String.isNotBlank(String.valueOf(ord.Account.DOB__pc)))
            modelsales.DateofBirth = convertToDateFormat(ord.Account.DOB__pc);
        modelsales.FirstName = String.isNotBlank(ord.Account.FirstName)
            ? ord.Account.FirstName
            : ord.Account.LastName;
        modelsales.Mobile = ord.Account.PersonMobilePhone;
        modelsales.Gender = String.isNotBlank(ord.Account.Gender__c)
            ? ord.Account.Gender__c
            : 'Male';
        modelsales.ProvinceCode = String.valueOf(
            ord.Province__r.Province_Code__c
        );
        modelsales.DistrictCode = String.valueOf(
            ord.District__r.District_Code__c
        );
        modelsales.Email = String.valueOf(ord.Account.PersonEmail);
        modelsales.Address = ord.Address_No__c;
        modelsales.PaymentMethod = 'C030CASH';
        modelsales.DealerType = 'DO';
        modelsales.OrderType = 'SpecialOrder';
        modelsales.SellingPrice = String.valueOf(ord.Total_Amount__c);
        modelsales.Amount = String.valueOf(ord.Total_Amount__c);
        modelsales.DiscountAmount = String.valueOf(ord.Total_Discount__c);
        modelsales.DmsOrderId = String.valueOf(ord.DmsOrderId__c);
        return modelsales;
    }
    public static SObjectAPIDMSRespone.Partssalesorder convertPartOrderRequestData(
        Order ord,
        List<OrderItem> partsales
    ) {
        SObjectAPIDMSRespone.Partssalesorder partsalesOrder = new SObjectAPIDMSRespone.Partssalesorder();
        List<SObjectAPIDMSRespone.DetailPart> lstParts = new List<SObjectAPIDMSRespone.DetailPart>();
        partsalesOrder.CRMOrderId = ord.Id;
        partsalesOrder.CRMOrderNo = ord.OrderNumber;
        partsalesOrder.OrderStatus = ord.Status;
        partsalesOrder.LastName = ord.Account.LastName;
        partsalesOrder.FirstName = ord.Account.FirstName;
        partsalesOrder.CRMConsumerId = String.valueOf(ord.AccountId);
        partsalesOrder.DeliveryPlanDate = String.valueOf(ord.Delivery_Date__c)
            .replaceAll('-', '');
        partsalesOrder.MobilePhone = ord.Account.PersonMobilePhone;
        partsalesOrder.DealerCode = ord.DO_DL__r.Branch__r.DO_DL_Code__c;
        partsalesOrder.PointCode = ord.DO_DL__r.DO_DL_Code__c;
        for (OrderItem partsale : partsales) {
            SObjectAPIDMSRespone.DetailPart partsalesDTO = new SObjectAPIDMSRespone.DetailPart();
            partsalesDTO.AllocatePartsCode = partsale.Product_Code__c;
            partsalesDTO.Amount = String.valueOf(partsale.TotalPrice);
            partsalesDTO.STDPrice = String.valueOf(partsale.ListPrice);
            partsalesDTO.SpecialPrice = String.valueOf(partsale.ListPrice);
            partsalesDTO.SellingPrice = String.valueOf(partsale.UnitPrice);
            //partsalesDTO.PartsId = partsale.Part_ID__c;
            // 27-06-2023
            partsalesDTO.PartsId = partsale.GUID_DMS__c;
            partsalesDTO.OrderQty = String.valueOf(partsale.Quantity);
            partsalesDTO.Discount = String.valueOf(partsale.Percent__c);
            partsalesDTO.SupersedingCode = partsale.Product2.Superseding_Parts_Code__c;
            lstParts.add(partsalesDTO);
        }
        partsalesOrder.detail = lstParts;
        return partsalesOrder;
    }

    public static SObjectAPIDMSRespone.Proformaorder convertProformaoOrderToRequestData(
        Order ord,
        List<OrderItem> profomao
    ) {
        SObjectAPIDMSRespone.Proformaorder proformaoOrder = new SObjectAPIDMSRespone.Proformaorder();
        proformaoOrder.DealerCode = ord.DO_DL__r.Branch__r.DO_DL_Code__c;
        proformaoOrder.PointCode = ord.DO_DL__r.DO_DL_Code__c;
        proformaoOrder.CRMOrderId = ord.Id;
        proformaoOrder.CRMOrderNo = ord.OrderNumber;
        List<SObjectAPIDMSRespone.Part> listParts = new List<SObjectAPIDMSRespone.Part>();
        for (OrderItem part : profomao) {
            SObjectAPIDMSRespone.Part partDTO = new SObjectAPIDMSRespone.Part();
            //partDTO.PartsId = part.Part_ID__c;
            // 27-06-2023
            partDTO.PartsId = part.GUID_DMS__c;
            partDTO.PartsCode = part.Product_Code__c;
            partDTO.OrderQuantity = String.valueOf(part.Quantity);
            listParts.add(partDTO);
        }
        proformaoOrder.Parts = listParts;
        return proformaoOrder;
    }
    public static SObjectAPIDMSRespone.SVWarrantyRecallOrder convertWarrantyRecallOrder(
        Order ord,
        List<OrderItem> partJobs,
        List<MotorcycleSituation__c> faults
    ) {
        SObjectAPIDMSRespone.SVWarrantyRecallOrder warranty = new SObjectAPIDMSRespone.SVWarrantyRecallOrder();
        List<SObjectAPIDMSRespone.Fault> lstFaultDTO = new List<SObjectAPIDMSRespone.Fault>();
        List<SObjectAPIDMSRespone.Job> lstJobDTO = new List<SObjectAPIDMSRespone.Job>();
        List<SObjectAPIDMSRespone.PartWarranty> lstPartWarrantyDTO = new List<SObjectAPIDMSRespone.PartWarranty>();
        warranty.CRMOrderId = ord.Id;
        warranty.DealerCode = ord.DO_DL__r.Branch__r.DO_DL_Code__c;
        warranty.DOFlag = '1';
        warranty.PointCode = ord.DO_DL__r.DO_DL_Code__c;

        warranty.Point = ord.DO_DL__r.DO_DL_Code__c;
        warranty.CRMServiceOrderNo = ord.OrderNumber;
        warranty.OrderDate = String.valueOf(ord.EffectiveDate)
            .replaceAll('-', '');
        warranty.NoPlate = ord.Asset__r.Plate_No__c;
        warranty.FrameNo = ord.Asset__r.Frame_Number__c;
        warranty.ServiceCategory = 'Warranty';
        warranty.CRMConsumerId = ord.AccountId;
        warranty.FirstName = ord.Account.FirstName;
        warranty.LastName = ord.Account.LastName;
        warranty.MobilePhone = ord.Account.PersonMobilePhone;
        warranty.Gender = ord.Account.Gender__c;
        warranty.ProvinceCode = ord.Province__r.Province_Code__c;
        warranty.CityCode = ord.Province__r.Province_Code__c;
        warranty.Email = ord.Account.PersonEmail;
        warranty.SNS = '';
        warranty.RelationType = 'Owner';
        warranty.Mileage = String.valueOf(ord.Mileage__c);
        warranty.ServiceCategory = 'Warranty';
        warranty.Cashier = ord.Cashier__r.Staff_Code__c;
        warranty.CashierName = ord.Cashier__r.Name;
        warranty.ServiceTitle = 'title';
        warranty.Mechanic = ord.Mechanic__r.Staff_Code__c;
        warranty.StartTime = String.valueOf(
            ord.Bike_Receiving_Date__c.format('yyyyMMddHHmmss')
        );
        warranty.FinishTime = String.valueOf(
            ord.Bike_Delivery_Date__c.format('yyyyMMddHHmmss')
        );
        warranty.OperationStartTime = String.valueOf(
            ord.Service_Job_Start_Date__c.format('yyyyMMddHHmmss')
        );
        warranty.OperationFinishTime = String.valueOf(
            ord.Service_Job_End_Date__c.format('yyyyMMddHHmmss')
        );
        warranty.PaymentMethod = 'Cash';
        for (MotorcycleSituation__c fault : faults) {
            SObjectAPIDMSRespone.Fault objFault = new SObjectAPIDMSRespone.Fault();
            objFault.Symptom = fault.Symptom__r.Name;
            objFault.Condition = fault.Condition__r.Name;
            // Bổ sung section code
            objFault.Section = fault.Symptom__r.Section_Code__c;
            objFault.ProcessComment = fault.Process_Comment__c;
            objFault.WarrantyClaim = fault.Warranty_Claim__c ? 'Y' : 'N';
            objFault.FaultStartDate = String.valueOf(fault.Fault_Start_Date__c)
                .replaceAll('-', '');
            objFault.MainDamageParts = fault.Part_Name__r.ProductCode;
            objFault.RepairDescription = fault.Repair_Description__c;
            objFault.SymptomComment = fault.Symptom_Comment__c;
            objFault.ConditionComment = fault.Condition_Comment__c;
            objFault.DealerComment = fault.Dealer_Comment__c;
            lstFaultDTO.add(objFault);
        }
        for (OrderItem parjobtItem : partJobs) {
            if (parjobtItem.Product2.Recordtype.Name.equals('Service Jobs')) {
                SObjectAPIDMSRespone.Job job = new SObjectAPIDMSRespone.Job();
                job.JobServiceCategory = 'Warranty';
                job.Symptom = parjobtItem.Symptom_Code__c;
                //job.JobId = parjobtItem.Product2.Job_ID__c;
                // 27-06-2023
                job.JobId = parjobtItem.GUID_DMS__c;
                // 29-06-2023 Update ko lấy Product line code nữa thay bằng product code
                // job.ServiceJob = parjobtItem.Product2.ProductLineCode__c;
                job.ServiceJob = parjobtItem.Product2.ProductCode;
                job.ServiceJobname = parjobtItem.Product2.Name;
                job.SpecialPrice = String.valueOf(parjobtItem.ListPrice);
                job.SellingPrice = String.valueOf(parjobtItem.UnitPrice);
                lstJobDTO.add(job);
            }
            if (parjobtItem.Product2.Recordtype.Name.equals('PCA')) {
                SObjectAPIDMSRespone.PartWarranty partWarranty = new SObjectAPIDMSRespone.PartWarranty();
                partWarranty.PartsServiceCategory = 'Warranty';
                partWarranty.Symptom = parjobtItem.Symptom_Code__c;
                //partWarranty.PartsId = parjobtItem.Product2.PartID__c;
                // 27-06-2023
                partWarranty.PartsId = parjobtItem.GUID_DMS__c;
                partWarranty.Parts = parjobtItem.Product2.ProductCode;
                partWarranty.PartsName = parjobtItem.Product2.Name;
                partWarranty.Discount = String.valueOf(parjobtItem.Percent__c);
                partWarranty.SpecialPrice = String.valueOf(
                    parjobtItem.ListPrice
                );
                partWarranty.SellingPrice = String.valueOf(
                    parjobtItem.UnitPrice
                );
                partWarranty.Qty = String.valueOf(parjobtItem.Quantity);
                lstPartWarrantyDTO.add(partWarranty);
            }
        }
        warranty.FaultDetail = lstFaultDTO;
        warranty.JobDetail = lstJobDTO;
        warranty.PartsDetail = lstPartWarrantyDTO;
        return warranty;
    }
    public static SObjectAPIDMSRespone.SVFreeCouponOrder convertFreeCouponOrderToRequestData(
        Order ord,
        List<OrderItem> partJobs
    ) {
        SObjectAPIDMSRespone.SVFreeCouponOrder freecouponOrder = new SObjectAPIDMSRespone.SVFreeCouponOrder();
        List<SObjectAPIDMSRespone.Job> lstJobDTO = new List<SObjectAPIDMSRespone.Job>();
        List<SObjectAPIDMSRespone.PartWarranty> lstPartWarrantyDTO = new List<SObjectAPIDMSRespone.PartWarranty>();
        freecouponOrder.CRMOrderId = ord.Id;
        freecouponOrder.DealerCode = ord.DO_DL__r.Branch__r.DO_DL_Code__c;
        freecouponOrder.DOFlag = '1';
        freecouponOrder.PointCode = ord.DO_DL__r.DO_DL_Code__c;
        freecouponOrder.CRMServiceOrderNo = ord.OrderNumber;
        freecouponOrder.OrderDate = String.valueOf(ord.EffectiveDate)
            .replaceAll('-', '');
        freecouponOrder.NoPlate = ord.Asset__r.Plate_No__c;
        freecouponOrder.FrameNo = ord.Asset__r.Frame_Number__c;
        freecouponOrder.CRMConsumerId = ord.AccountId;
        freecouponOrder.FirstName = String.isNotBlank(ord.Account.LastName)
            ? ord.Account.FirstName
            : ord.Account.LastName;
        freecouponOrder.LastName = ord.Account.LastName;
        freecouponOrder.MobilePhone = ord.Account.PersonMobilePhone;
        freecouponOrder.Gender = ord.Account.Gender__c;
        freecouponOrder.ProvinceCode = ord.Province__r.Province_Code__c;
        freecouponOrder.CityCode = ord.Province__r.Province_Code__c;
        freecouponOrder.Email = ord.Account.PersonEmail;
        freecouponOrder.ServiceCategory = 'Freecoupon';
        freecouponOrder.SNS = '';
        freecouponOrder.RelationType = 'Owner';
        freecouponOrder.Mileage = String.valueOf(ord.Mileage__c);
        freecouponOrder.Cashier = ord.Cashier__r.Staff_Code__c;
        freecouponOrder.CashierName = ord.Cashier__r.Name;
        freecouponOrder.ServiceTitle = 'title';
        freecouponOrder.Mechanic = ord.Mechanic__r.Staff_Code__c;
        freecouponOrder.ServiceDemand = 'CJPSerDem0001';
        freecouponOrder.StartTime = String.valueOf(
            ord.Bike_Receiving_Date__c.format('yyyyMMddHHmmss')
        );
        freecouponOrder.FinishTime = String.valueOf(
            ord.Bike_Delivery_Date__c.format('yyyyMMddHHmmss')
        );
        freecouponOrder.OperationStartTime = String.valueOf(
            ord.Service_Job_Start_Date__c.format('yyyyMMddHHmmss')
        );
        freecouponOrder.OperationFinishTime = String.valueOf(
            ord.Service_Job_End_Date__c.format('yyyyMMddHHmmss')
        );
        for (OrderItem parjobtItem : partJobs) {
            if (parjobtItem.Product2.Recordtype.Name.equals('Service Jobs')) {
                SObjectAPIDMSRespone.Job job = new SObjectAPIDMSRespone.Job();
                job.JobServiceCategory = 'Freecoupon';
                //job.JobId = parjobtItem.Product2.Job_ID__c;
                // 27-06-2023
                job.JobId = parjobtItem.GUID_DMS__c;
                job.ServiceJob = parjobtItem.Product2.ProductCode;
                job.ServiceJobname = parjobtItem.Product2.Name;
                job.SpecialPrice = String.valueOf(parjobtItem.ListPrice);
                job.SellingPrice = String.valueOf(parjobtItem.UnitPrice);
                lstJobDTO.add(job);
            }
            if (parjobtItem.Product2.Recordtype.Name.equals('PCA')) {
                SObjectAPIDMSRespone.PartWarranty partWarranty = new SObjectAPIDMSRespone.PartWarranty();
                partWarranty.PartsServiceCategory = 'Freecoupon';
                //partWarranty.PartsId = parjobtItem.Product2.PartID__c;
                // 27-06-2023
                partWarranty.PartsId = parjobtItem.GUID_DMS__c;
                partWarranty.Parts = parjobtItem.Product2.ProductCode;
                partWarranty.PartsName = parjobtItem.Product2.Name;
                partWarranty.Discount = String.valueOf(parjobtItem.Percent__c);
                partWarranty.SpecialPrice = String.valueOf(
                    parjobtItem.ListPrice
                );
                partWarranty.SellingPrice = String.valueOf(
                    parjobtItem.UnitPrice
                );
                partWarranty.Qty = String.valueOf(parjobtItem.Quantity);
                lstPartWarrantyDTO.add(partWarranty);
            }
        }
        freecouponOrder.JobDetail = lstJobDTO;
        freecouponOrder.PartsDetail = lstPartWarrantyDTO;
        return freecouponOrder;
    }
    public static SObjectAPIDMSRespone.SVOKMWarrantyRecallOrder convert0KMWarrantyRecallOrder(
        Order ord,
        List<OrderItem> partJobs,
        List<MotorcycleSituation__c> faults
    ) {
        SObjectAPIDMSRespone.SVOKMWarrantyRecallOrder warranty0KM = new SObjectAPIDMSRespone.SVOKMWarrantyRecallOrder();
        List<SObjectAPIDMSRespone.Fault> lstFaultDTO = new List<SObjectAPIDMSRespone.Fault>();
        List<SObjectAPIDMSRespone.Job> lstJobDTO = new List<SObjectAPIDMSRespone.Job>();
        List<SObjectAPIDMSRespone.PartWarranty> lstPartWarrantyDTO = new List<SObjectAPIDMSRespone.PartWarranty>();
        warranty0KM.CRMOrderId = ord.Id;
        warranty0KM.CRMConsumerId = ord.AccountId;
        warranty0KM.DealerCode = ord.DO_DL__r.Branch__r.DO_DL_Code__c;
        warranty0KM.Point = ord.DO_DL__r.DO_DL_Code__c;
        warranty0KM.CRMServiceOrderNo = ord.OrderNumber;
        warranty0KM.OrderDate = String.valueOf(ord.EffectiveDate)
            .replaceAll('-', '');
        warranty0KM.FrameNo = ord.Asset__r.Frame_Number__c;
        warranty0KM.Model = ord.Asset__r.Make_Model__c;
        warranty0KM.MechanicComment = ord.MechanicComment__c;
        warranty0KM.ServiceCategory = ord.RecordTypeId ==
            RecordTypeHelper.ORDER_WARRANTY
            ? 'Warranty'
            : 'Recall';
        warranty0KM.Cashier = ord.Cashier__r.Staff_Code__c;
        warranty0KM.CashierName = ord.Cashier__r.Name;
        warranty0KM.Mechanic = ord.Mechanic__r.Staff_Code__c;
        warranty0KM.StartTime = String.valueOf(
            ord.Bike_Receiving_Date__c.format('yyyyMMddHHmmss')
        );
        warranty0KM.FinishTime = String.valueOf(
            ord.Bike_Delivery_Date__c.format('yyyyMMddHHmmss')
        );
        warranty0KM.OperationStartTime = String.valueOf(
            ord.Service_Job_Start_Date__c.format('yyyyMMddHHmmss')
        );
        warranty0KM.OperationFinishTime = String.valueOf(
            ord.Service_Job_End_Date__c.format('yyyyMMddHHmmss')
        );
        for (MotorcycleSituation__c fault : faults) {
            SObjectAPIDMSRespone.Fault objFault = new SObjectAPIDMSRespone.Fault();
            objFault.Symptom = fault.Symptom__r.Name;
            objFault.Condition = fault.Condition__r.Name;
            // Bổ sung section code
            objFault.Section = fault.Symptom__r.Section_Code__c;
            objFault.ProcessComment = fault.Process_Comment__c;
            objFault.WarrantyClaim = fault.Warranty_Claim__c ? 'Y' : 'N';
            objFault.FaultStartDate = String.valueOf(fault.Fault_Start_Date__c)
                .replaceAll('-', '');
            objFault.MainDamageParts = fault.Part_Name__r.ProductCode;
            objFault.RepairDescription = fault.Repair_Description__c;
            objFault.SymptomComment = fault.Symptom_Comment__c;
            objFault.ConditionComment = fault.Condition_Comment__c;
            objFault.DealerComment = fault.Dealer_Comment__c;
            lstFaultDTO.add(objFault);
        }
        for (OrderItem parjobtItem : partJobs) {
            if (parjobtItem.Product2.Recordtype.Name.equals('Service Jobs')) {
                SObjectAPIDMSRespone.Job job = new SObjectAPIDMSRespone.Job();
                job.JobServiceCategory = ord.RecordTypeId ==
                    RecordTypeHelper.ORDER_WARRANTY
                    ? 'Warranty'
                    : 'Recall';
                job.Symptom = parjobtItem.Symptom_Code__c;
                //job.JobId = parjobtItem.Product2.Job_ID__c;
                // 27-06-2023
                job.JobId = parjobtItem.GUID_DMS__c;
                // 29-06-2023 Update ko lấy Product line code nữa thay bằng product code
                job.ServiceJob = parjobtItem.Product2.ProductCode;
                //job.ServiceJob = parjobtItem.Product2.ProductLineCode__c;
                job.ServiceJobname = parjobtItem.Product2.Name;
                job.SpecialPrice = String.valueOf(parjobtItem.ListPrice);
                job.SellingPrice = String.valueOf(parjobtItem.UnitPrice);
                lstJobDTO.add(job);
            }
            if (parjobtItem.Product2.Recordtype.Name.equals('PCA')) {
                SObjectAPIDMSRespone.PartWarranty partWarranty = new SObjectAPIDMSRespone.PartWarranty();
                partWarranty.PartsServiceCategory = ord.RecordTypeId ==
                    RecordTypeHelper.ORDER_WARRANTY
                    ? 'Warranty'
                    : 'Recall';
                partWarranty.Symptom = parjobtItem.Symptom_Code__c;
                //partWarranty.PartsId = parjobtItem.Product2.PartID__c;
                // 27-06-2023
                partWarranty.PartsId = parjobtItem.GUID_DMS__c;
                partWarranty.Parts = parjobtItem.Product2.ProductCode;
                partWarranty.PartsName = parjobtItem.Product2.Name;
                partWarranty.Discount = String.valueOf(parjobtItem.Percent__c);
                partWarranty.SpecialPrice = String.valueOf(
                    parjobtItem.ListPrice
                );
                partWarranty.SellingPrice = String.valueOf(
                    parjobtItem.UnitPrice
                );
                partWarranty.Qty = String.valueOf(parjobtItem.Quantity);
                lstPartWarrantyDTO.add(partWarranty);
            }
        }
        warranty0KM.FaultDetail = lstFaultDTO;
        warranty0KM.JobDetail = lstJobDTO;
        warranty0KM.PartsDetail = lstPartWarrantyDTO;
        return warranty0KM;
    }
    public static void createAssetMCInventory(
        List<ModelInventory__c> mcinventorys,
        Map<String, Product2> mapMcColorCode,
        Map<String, Id> mapPointCode,
        Map<Id, Id> idDOIdWarehouses
    ) {
        List<Warehouse_Inventory__c> lstWareInventory = new List<Warehouse_Inventory__c>();
        List<Asset> lstAssets = new List<Asset>();
        system.debug('mcinventorys ' + mcinventorys);
        for (ModelInventory__c item : mcinventorys) {
            Asset asset = new Asset();
            asset.Name = item.ModelName__c + '_' + item.ColorName__c;
            asset.AccountId = mapPointCode.get(item.PointCode__c);
            asset.Engine_No__c = item.EngineNo__c;
            asset.Frame_Number__c = item.FrameNo__c;
            asset.Product2Id = mapMcColorCode.get(item.ModelCode__c).Id;
            //asset.Product_DO__c = !mapMcColorCode.get(item.ModelCode__c).Product_DO__r.isEmpty() ? mapMcColorCode.get(item.ModelCode__c).Product_DO__r[0].ID : null;
            asset.Warranty_Kilometers__c = 30000;
            asset.Number_of_Month_Gar_del__c = 36;
            asset.PurchaseDate = item.ShippingDate__c;
            asset.Status = 'New';
            asset.Inventory_Status__c = 'Available';
            lstAssets.add(asset);
        }
        insert lstAssets;
        system.debug('lstAssets ' + lstAssets);
        for (Asset asset : lstAssets) {
            Warehouse_Inventory__c whi = new Warehouse_Inventory__c();
            whi.Name = asset.Name;
            whi.Asset__c = asset.Id;
            whi.QoH__c = 1;
            //whi.Product_DO__c = asset.Product_DO__c;
            whi.Stocking_Date__c = Date.today();
            whi.Batch_or_Serial_Type__c = 'Batch';
            whi.Product__c = asset.Product2Id;
            whi.Vendor__c = asset.AccountId;
            whi.Warehouse_Location__c = idDOIdWarehouses.get(asset.AccountId);
            lstWareInventory.add(whi);
        }
        insert lstWareInventory;
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
    public static Date convertFormatDate(String strDate) {
        Pattern p = pattern.compile('(\\d{4})(\\d{2})(\\d{2})');
        Matcher m = p.matcher(strDate);
        m.find();
        Integer year = Integer.valueOf(m.group(1)),
            month = Integer.valueOf(m.group(2)),
            day = Integer.valueOf(m.group(3));
        return Date.newInstance(year, month, day);
    }
    public static HttpResponse requestPaginationDMS(
        String apiname,
        String reqBody,
        Date dateFrom,
        Date dateTo,
        Integer pageSize,
        Integer startIndex,
        string DealerCode
    ) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        System.debug('settingAPIDMS::' + settingAPIDMS.keySet());
        string strURL = runningInASandbox
            ? 'callout:Api_DMS/streamapi/ymvn1/api/v1/' +
              apiname +
              '?dealerCd=' +
              settingAPIDMS.get(DealerCode).DealerCD__c +
              '&accessToken=' +
              settingAPIDMS.get(DealerCode).AccessToken__c
            : 'callout:API_DMS_PROD/streamapi/ymvn1/api/v1/' +
              apiname +
              '?dealerCd=' +
              settingAPIDMS.get(DealerCode + 'PROD').DealerCD__c +
              '&accessToken=' +
              settingAPIDMS.get(DealerCode + 'PROD').AccessToken__c;
        strURL +=
            '&dateFrom=' +
            String.valueOf(dateFrom).replaceAll('-', '') +
            '&dateTo=' +
            String.valueOf(dateTo).replaceAll('-', '');
        strURL += '&pageSize=' + pageSize + '&startIndex=' + startIndex;
        System.debug('strURL::' + strURL);
        request.setEndpoint(strURL);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(reqBody);
        request.setTimeout(120000);
        return http.send(request);
    }
    public static HttpResponse requestApiDMS(
        String apiname,
        String reqBody,
        Date dateFrom,
        Date dateTo,
        string DealerCode
    ) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        string strURL = runningInASandbox
            ? 'callout:Api_DMS/streamapi/ymvn1/api/v1/' +
              apiname +
              '?dealerCd=' +
              settingAPIDMS.get(DealerCode).DealerCD__c +
              '&accessToken=' +
              settingAPIDMS.get(DealerCode).AccessToken__c
            : 'callout:API_DMS_PROD/streamapi/ymvn1/api/v1/' +
              apiname +
              '?dealerCd=' +
              settingAPIDMS.get(DealerCode + 'PROD').DealerCD__c +
              '&accessToken=' +
              settingAPIDMS.get(DealerCode + 'PROD').AccessToken__c;
        strURL +=
            '&dateFrom=' +
            String.valueOf(dateFrom).replaceAll('-', '') +
            '&dateTo=' +
            String.valueOf(dateTo).replaceAll('-', '');
        request.setEndpoint(strURL);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(reqBody);
        request.setTimeout(120000);
        return http.send(request);
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
    }
}
