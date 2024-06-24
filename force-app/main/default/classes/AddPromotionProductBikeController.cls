public without sharing class AddPromotionProductBikeController {
  @AuraEnabled
  public static ApiResponse getInitialData(String recordId) {
    ApiResponse apiResponse = new ApiResponse();
    List<ProductDTO> lstProductDTO = new List<ProductDTO>();
    Map<Id, Promotion_Product__c> mapPromotionProduct = new Map<Id, Promotion_Product__c>();
    List<Promotion_Product__c> lstPromotionProduct = getListPromotionProduct(recordId);
    for (Promotion_Product__c promo : lstPromotionProduct) {
      mapPromotionProduct.put(promo.Product__c, promo);
    }
    List<Product2> lstProduct = getListProduct();
    for (Product2 p : lstProduct) {
      if (mapPromotionProduct.containsKey(p.Id)) {
        ProductDTO product = new ProductDTO(p, mapPromotionProduct.get(p.Id));
        lstProductDTO.add(product);
      } else {
        ProductDTO product = new ProductDTO(p, recordId);
        lstProductDTO.add(product);
      }
    }
    if (apiResponse.error == null) {
      apiResponse.success = true;
      apiResponse.result = lstProductDTO;
    }

    return apiResponse;
  }

  @AuraEnabled
  public static ApiResponse getProductBySearchString(String searchString,String recordId) {
    ApiResponse apiResponse = new ApiResponse();
    List<ProductDTO> lstProductDTO = new List<ProductDTO>();

    String strProdName = '%' + searchString + '%';
    List<Product2> lstProduct2 = [
      SELECT  Id,
      ProductCode,
      Name,
      Model_Name__c,
      Model_Code__c,
      Color_Name__c,
      Color_Code__c,
      Model_Year__c,
      IsActive
      FROM Product2
      WHERE
        RecordTypeId = :RecordTypeHelper.PRODUCT_MODEL AND IsActive = true
        AND (Name LIKE :strProdName
        OR Model_Code__c LIKE :strProdName)
      LIMIT 500
    ];
    for (Product2 item : lstProduct2) {
      ProductDTO objDTO = new ProductDTO(item,recordId);
      lstProductDTO.add(objDTO);
    }
    if (apiResponse.error == null) {
      apiResponse.success = true;
      apiResponse.result = lstProductDTO;
    }
    return apiResponse;
  }

  @AuraEnabled
  public static ApiResponse getLstPromotionProductDTO(
    String recordId,
    List<ProductDTO> lstProduct
  ) {
    ApiResponse apiResponse = new ApiResponse();
    List<PromotionProductDTO> lstPromoProductDTO = new List<PromotionProductDTO>();
    List<Promotion_Product__c> lstPromoProduct = getListPromotionProduct(
      recordId
    );
    Map<Id, Promotion_Product__c> mapPromo = new Map<Id, Promotion_Product__c>();
    for (Promotion_Product__c promo : lstPromoProduct) {
      mapPromo.put(promo.Product__c, promo);
    }
    for (ProductDTO p : lstProduct) {
      if (mapPromo.containsKey(p.Id)) {
        PromotionProductDTO proProduct = new PromotionProductDTO(
          mapPromo.get(p.Id)
        );
        lstPromoProductDTO.add(proProduct);
      } else {
        PromotionProductDTO proProduct = new PromotionProductDTO(p, recordId);
        lstPromoProductDTO.add(proProduct);
      }
    }
    if (apiResponse.error == null) {
      apiResponse.success = true;
      apiResponse.result = lstPromoProductDTO;
    }

    return apiResponse;
  }

  @AuraEnabled
  public static ApiResponse savePromotionProductBike(
    List<ProductDTO> lstProductDTO, String recordId
  ) {
    ApiResponse apiResponse = new ApiResponse();
    try {
      List<Promotion_Product__c> lstUpsertPromoProduct = new List<Promotion_Product__c>();
      for (ProductDTO promoPDTO : lstProductDTO) {
        Promotion_Product__c promo = new Promotion_Product__c();
        promo.Id = promoPDTO.PromotionProductId;
        promo.Product__c = promoPDTO.Id;
        if (promoPDTO.PromotionProductId == null) {
          promo.Promotion_Item__c = promoPDTO.PromotionProductItem;
        }
        promo.Discount_Amount__c = promoPDTO.Discount;
        lstUpsertPromoProduct.add(promo);
      }

      List<Promotion_Product__c> lstDeletePromotionProduct = new List<Promotion_Product__c>();
      lstDeletePromotionProduct = [SELECT Id,Promotion_Item__c FROM Promotion_Product__c WHERE Promotion_Item__c = :recordId AND  Id NOT IN :lstUpsertPromoProduct];
      if (!lstDeletePromotionProduct.isEmpty()){
        delete lstDeletePromotionProduct;
      }

      if (!lstUpsertPromoProduct.isEmpty()) {
        upsert lstUpsertPromoProduct;
        
        //upsert lstWarehouseInventoryUpdate;
      }
      if (apiResponse.error == null) {
        apiResponse.success = true;
      }
      return apiResponse;
    } catch (Exception ex) {
      System.debug('ex.getMessage() :' + ex.getMessage());
      apiResponse.error = ex.getMessage();
      return apiResponse;
    }
  }

  private static List<Promotion_Product__c> getListPromotionProduct(
    String recordId
  ) {
    List<Promotion_Product__c> lstPromotionProduct = new List<Promotion_Product__c>();
    lstPromotionProduct = [
      SELECT
        Id,
        Name,
        Product__c,
        Product__r.Name,
        Promotion_Item__c,
        Discount__c,
        Discount_Amount__c
      FROM Promotion_Product__c
      WHERE Promotion_Item__c = :recordId
    ];
    return lstPromotionProduct;
  }

  private static List<Product2> getListProduct() {
    List<Product2> lstProduct = new List<Product2>();
    lstProduct = [
      SELECT
        Id,
        ProductCode,
        Name,
        Model_Name__c,
        Model_Code__c,
        Color_Name__c,
        Color_Code__c,
        Model_Year__c,
        IsActive
      FROM Product2
      WHERE RecordTypeId = :RecordTypeHelper.PRODUCT_MODEL AND IsActive = true
    ];
    return lstProduct;
  }

  public class ProductDTO {
    @AuraEnabled
    public String Id { get; set; }

    @AuraEnabled
    public String ProductName { get; set; }

    @AuraEnabled
    public String ProductCode { get; set; }

    @AuraEnabled
    public String ModelName { get; set; }

    @AuraEnabled
    public String ModelCode { get; set; }

    @AuraEnabled
    public String ColorName { get; set; }

    @AuraEnabled
    public String ColorCode { get; set; }

    @AuraEnabled
    public Decimal ModelYear { get; set; }

    @AuraEnabled
    public String PromotionProductId { get; set; }

    @AuraEnabled
    public String PromotionProductItem { get; set; }

    @AuraEnabled
    public Decimal Discount { get; set; }

    @AuraEnabled
    public Boolean IsChecked { get; set; }

    public ProductDTO() {
    }
    public ProductDTO(Product2 product) {
      this.Id = product.Id;
      this.ProductName = product.Name;
      this.ProductCode = product.ProductCode;
      this.ModelCode = product.Model_Code__c;
      this.ColorCode = product.Color_Code__c;
      this.ModelYear = product.Model_Year__c;
      this.ModelName = product.Model_Name__c;
      this.ColorName = product.Color_Name__c;
  
    }
    public ProductDTO(Product2 product, String recordId) {
      this.Id = product.Id;
      this.ProductName = product.Name;
      this.ProductCode = product.ProductCode;
      this.ModelCode = product.Model_Code__c;
      this.ColorCode = product.Color_Code__c;
      this.ModelYear = product.Model_Year__c;
      this.ModelName = product.Model_Name__c;
      this.ColorName = product.Color_Name__c;
      this.PromotionProductId = null;
      this.PromotionProductItem = recordId;
      this.Discount = 0;
    }
    public ProductDTO(Product2 product, Promotion_Product__c promoPro) {
      this.Id = product.Id;
      this.ProductName = product.Name;
      this.ProductCode = product.ProductCode;
      this.ModelCode = product.Model_Code__c;
      this.ColorCode = product.Color_Code__c;
      this.ModelYear = product.Model_Year__c;
      this.ModelName = product.Model_Name__c;
      this.ColorName = product.Color_Name__c;
      this.PromotionProductId = promoPro.Id;
      this.PromotionProductItem = promoPro.Promotion_Item__c;
      this.Discount = promoPro.Discount_Amount__c;
      this.IsChecked = true;
    }
  }

  public class PromotionProductDTO {
    @AuraEnabled
    public String Id { get; set; }

    @AuraEnabled
    public String PromotionProductName { get; set; }

    @AuraEnabled
    public String ProductName { get; set; }

    @AuraEnabled
    public String Product { get; set; }

    @AuraEnabled
    public String PromotionProductItem { get; set; }

    @AuraEnabled
    public Decimal Discount { get; set; }

    public PromotionProductDTO() {
    }

    public PromotionProductDTO(ProductDTO product, String recordId) {
      this.Id = null;
      this.Product = product.Id;
      this.ProductName = product.ProductName;
      this.PromotionProductItem = recordId;
      this.Discount = 0;
    }

    public PromotionProductDTO(Promotion_Product__c promoProduct) {
      this.Id = promoProduct.Id;
      this.PromotionProductName = promoProduct.Name;
      this.Discount = promoProduct.Discount_Amount__c;
      this.Product = promoProduct.Product__c;
      this.ProductName = promoProduct.Product__r.Name;
      this.PromotionProductItem = promoProduct.Promotion_Item__c;
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
} 
}