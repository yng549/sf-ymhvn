public class SObjectAPIDMSRespone {
  public class VATProductData {
    public string ProductCode;
    public string nType;
    public integer VAT;
  }
  public class CustomerData {
    public string CustomerId;
    public string DealerCode;
    public string PointCode;
    public string LastName;
    public string MiddleName;
    public string FirstName;
    public string CustomerType;
    public string ConsumerType;
    public string Mobile;
    public string Mobile2;
    public string Email;
    public string Gender;
    public string Birthday;
    public string Age;
    public string JobTittle;
    public string ProvinceCode;
    public string ProvinceName;
    public string DistrictCode;
    public string Address;
    public string IdNo;
    public string OrderId;
    public string OrderType;
    public string nType;
    public string CreateDate;
    public string LastModify;
  }
  public class PartData {
    public string PartNo;
    public string PartNameEng;
    public string PartNameNative;
    public string SupersedingPart;
    public string ProductCategory;
    public string PartSizeHigh;
    public string PartSizeWidth;
    public string PartSizeLong;
    public string PartWeight;
    public string PurchaseLot;
    public string SalesLot;
    public decimal RetailPrice;
    public string NonSalesId;
    public string RetailPriceRevisionDate;
    public string WholeSalesRevisionDate;
    public string SupersedingRevisionDate;
    public string OptionCode1;
    public string OptionName1;
    public string RegisterDate;
    public string DealerCode;
    public string PointCode;
    public string PartsId;
    public string CreateDate;
    public string LastModify;
  }
  public class ModelData {
    public string ModelType;
    public string ModelTypeName;
    public string ModelCode;
    public string ModelName;
    public string EffectiveDate;
    public string OutEffectiveDate;
    public string ProductCode;
    public string ProductSalesName;
    public string ColorCode;
    public string ColorName;
    public string RegisteredModel;
    public string ModelYear;
    public string Displacement;
    public string StdRetailPrice;
    public string DealerCode;
    public string PointCode;
    public string OptionName1;
    public string ModelId;
  }
  public class ServiceJobData {
    public string hProductLineCode;
    public string dJobId;
    public string dDealerCode;
    public string dPointCode;
    public string dJobCode;
    public string dJobDescriptionEng;
    public string dJobDescriptionLocal;
    public string dJobDescriptionLocalForDo;
    public string UpdateDate;
  }
  /*IV.6	mcinventoryData   Data start region*/
  public class ModelInventoryData {
    public string SupplierCode;
    public string DealerCode;
    public string PointCode;
    public string InternalDeliveryNoteNo;
    public string ShippingDate;
    public string InvoiceNo;
    public string ModelCode;
    public string ModelName;
    public string ColorCode;
    public string ColorName;
    public string BarCode;
    public string FrameNo;
    public string EngineNo;
    public string AssemblyDate;
    public Integer SalesPrice;
    public Integer SalesVat;
  }
  /*IV.6	mcinventoryData end region*/

  /*IV.7	mcpricing Data start region*/
  public class ModelPricingData {
    public string ModelCode;
    public string ModelName;
    public string Displacement;
    public Decimal EmployeePrice;
    public Decimal RetailPrice;
  }

  // IV.8	jobpricing Data

  public class Productlinedate {
    public String ProductLineCode;
  }
  public class JobMasterData {
    public FlatrateGroupDTOs FlatrateGroups;
  }
  public class FlatrateGroupDTOs {
    public List<FlatrateDetail> detail;
  }
  public class FlatrateDetail {
    public JobDetail jobs;
  }
  public class JobDetail {
    public string JobCode;
    public string FlatRate;
    public string LabourCost;
    public string totalCost;
  }
  // IV.8	jobpricing Data

  /*IV.9	mcpricing Data end region*/
  public class PartManifestData {
    public string ManifestItemID;
    public string DealerCode;
    public string InvoiceNo;
    public string YourOrderNo;
    public string PartsNo;
    public string PartsNoOrdered;
    public integer Price;
    public string CaseNo;
    public integer PackingQty;
    public string ShippedDate;
    public string InvoiceSeqNo;
    public string ShipmentNo;
  }

  /*IV.10	proformaorder Data start region*/
  public class Proformaorder {
    public string DealerCode;
    public string CRMOrderId;
    public string CRMOrderNo;
    public string PointCode;
    public List<Part> Parts;
  }
  public class Part {
    public string PartsId;
    public string PartsCode;
    public string OrderQuantity;
  }
  /*IV.10	proformaorder Data end region*/

  /*IV.11	partssalesorder Data start region*/
  public class Partssalesorder {
    public string CRMOrderId;
    public string CRMOrderNo;
    public string OrderStatus;
    public string DealerCode;
    public string LastName;
    public string MiddleName;
    public string FirstName;
    public string CRMConsumerId;
    public string DeliveryPlanDate;
    public string MobilePhone;
    public string PointCode;
    public List<DetailPart> detail;
  }
  public class DetailPart {
    public string PartsId;
    public string AllocatePartsCode;
    public string SupersedingCode;
    public string OrderQty;
    public string STDPrice;
    public string SpecialPrice;
    public string Discount;
    public string SellingPrice;
    public string Amount;
  }
  /*IV.11	partssalesorder Data end region*/

  /*IV.12	mcsalesorder Data start region start region*/
  public class Modelcsalesorder {
    public string CRMOrderId;
    public string CRMOrderNo;
    public string DealerCode;
    public string PointCode;
    public string SalesDate;
    public string DateofBirth;
    public string EinvoiceFlag;
    public string FrameNo;
    public string RegistrationDate;
    public string IdNo;
    public string CRMConsumerId;
    public string LastName;
    public string MiddleName;
    public string FirstName;
    public string BusinessName;
    public string Mobile;
    public string SNS;
    public string Gender;
    public string ProvinceCode;
    public string DistrictCode;
    public string Email;
    public string Address;
    public string Occupation;
    public string PaymentMethod;
    public string CusTaxCode;
    public string DealerType;
    public string OrderType;
    public string SellingPrice;
    public string TaxRate;
    public string TaxAmount;
    public string DiscountAmount;
    public string Amount;
  }
  /*IV.12	mcsalesorder Data start region end region*/

  /*IV.13	svwarrantyorder, svrecallorder  Data start region start region*/
  public class SVWarrantyRecallOrder {
    public string CRMOrderId;
    public string DealerCode;
    public string PointCode;
    public string DOFlag;
    public string Point;
    public string CRMServiceOrderNo;
    public string OrderDate;
    public string NoPlate;
    public string FrameNo;
    public string CRMConsumerId;
    public string FirstName;
    public string MiddleName;
    public string LastName;
    public string ModelType;
    public string CustaxCode;
    public string MobilePhone;
    public string Gender;
    public string ProvinceCode;
    public string CityCode;
    public string Email;
    public string ProcessComment;
    public string SNS;
    public string RelationType;
    public string Mileage;
    public string ServiceCategory;
    public string Cashier;
    public string CashierName;
    public string ServiceTitle;
    public string Mechanic;
    public string StartTime;
    public string FinishTime;
    public string OperationStartTime;
    public string OperationFinishTime;
    public string PaymentMethod;
    public List<Fault> FaultDetail;
    public List<Job> JobDetail;
    public List<PartWarranty> PartsDetail;
  }
  public class Fault {
    public string Symptom;
    public string Condition;
    public string Section;
    public string WarrantyClaim;
    public string FaultStartDate;
    public string MainDamageParts;
    public string RepairDescription;
    public string SymptomComment;
    public string ConditionComment;
    public string ProcessComment;
    public string DealerComment;
  }
  public class Job {
    public string JobServiceCategory;
    public string JobServiceDemand;
    public string Symptom;
    public string JobId;
    public string ServiceJob;
    public string ServiceJobname;
    public string ServicePackage;
    public string SpecialPrice;
    public string SellingPrice;
  }
  public class PartWarranty {
    public string PartsServiceCategory;
    public string PartsServiceDemand;
    public string Symptom;
    public string PartsId;
    public string Parts;
    public string PartsName;
    public string Discount;
    public string SpecialPrice;
    public string SellingPrice;
    public string Qty;
  }
  /*IV.12	svwarrantyorder Data start region end region*/

  /*IV.14	svfreecouponsorder  Data start region start region*/
  public class SVFreeCouponOrder {
    public string CRMOrderId;
    public string DealerCode;
    public string DOFlag;
    public string PointCode;
    public string CRMServiceOrderNo;
    public string OrderDate;
    public string NoPlate;
    public string FrameNo;
    public string CRMConsumerId;
    public string FirstName;
    public string MiddleName;
    public string LastName;
    public string ServiceDemand;
    public string ModelType;
    public string CustaxCode;
    public string MobilePhone;
    public string Gender;
    public string ProvinceCode;
    public string CityCode;
    public string Email;
    public string SNS;
    public string RelationType;
    public string Mileage;
    public string ServiceCategory;
    public string Cashier;
    public string CashierName;
    public string ServiceTitle;
    public string Mechanic;
    public string StartTime;
    public string FinishTime;
    public string OperationStartTime;
    public string OperationFinishTime;
    public string PaymentMethod;
    public List<Job> JobDetail;
    public List<PartWarranty> PartsDetail;
  }
  /*IV.14	svfreecouponsorder Data start region end region*/

  /*IV.16-17	0kmsvwarrantyorder Data start region start region*/
  public class SVOKMWarrantyRecallOrder {
    public string CRMOrderId;
    public string DealerCode;
    public string Point;
    public string CRMConsumerId;
    public string CRMServiceOrderNo;
    public string OrderDate;
    public string FrameNo;
    public string Model;
    public string MechanicComment;
    public string ServiceCategory;
    public string Cashier;
    public string CashierName;
    public string ServiceTitle;
    public string Mechanic;
    public string StartTime;
    public string FinishTime;
    public string OperationStartTime;
    public string OperationFinishTime;
    public List<Fault> FaultDetail;
    public List<Job> JobDetail;
    public List<PartWarranty> PartsDetail;
  }
  /*IV.16	0kmsvwarrantyorder Data end region end region*/

  /*IV.18 warranty Data (warranty service request) start region start region*/
  public class WarrantyServiceRequest {
    public WarrantyItem UnitWarranty;
  }
  public class WarrantyItem {
    public Id idAsset;
    public string FrameNo;
    public string WarrantyEffectiveDate;
    public string WarrantyExpiredDate;
    public string WarrantyMileage;
    public string WarrantyPolicyType;
    public List<CouponItem> coupons;
  }
  public class CouponItem {
    public coupondetail coupon;
  }
  public class coupondetail {
    public string CouponCategoryLevel;
    public string ServiceDate;
    public string Mileage;
  }
  /*IV.18	warranty Data (warranty service request) end region end region*/

  /*IV.19 svpayment Data start region start region*/
  public class Payment {
    public string PaymentControlNo;
    public string PaymentDealerCode;
    public string YnspireAccountDate;
    public string AccountingMonth;
    public List<PaymentDetail> detaildatas;
  }
  public class PaymentDetail {
    public string ServiceRequestID;
    public decimal PaymentAmount;
    public string RequestDate;
    public string ServiceCategory;
  }
  /*IV.19	svpayment Data end region end region*/

  /*IV.20	recallvalidationcheck start region start region*/
  public class RecallBody {
    public string frameNo;
  }
  public class RecallValidation {
    public string FrameNo;
    public string CampaignNo;
    public string BulletinNo;
    public string Status;
  }
  /*IV.20	recallvalidationcheck end region end region*/
  /*IV.21	Bigbike model Data  */

  public class CouponCategory {
    public String CoupCtgCode;
    public String PlCd;
    public List<DetailItem> detail;
  }

  public class DetailItem {
    public CoupCtgLevels CoupCtgLevels;
    public ModelCodes ModelCodes;
  }

  public class CoupCtgLevels {
    public String CoupCtgLevel;
    public String UsedMonthFrom;
    public String UsedMonthTo;
    public String MileageFrom;
    public String MileageTo;
  }

  public class ModelCodes {
    public String ModelCode;
  }
  /*IV.21 JSON Response end region*/
}
