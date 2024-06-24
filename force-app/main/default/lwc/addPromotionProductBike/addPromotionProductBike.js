import { LightningElement ,api, wire, track} from 'lwc';      
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getInitialData from '@salesforce/apex/AddPromotionProductBikeController.getInitialData';
import getProductBySearchString from '@salesforce/apex/AddPromotionProductBikeController.getProductBySearchString';
import savePromotionProductBike from '@salesforce/apex/AddPromotionProductBikeController.savePromotionProductBike';

export default class AddPromotionProductBike extends LightningElement {


 
      @api productList ;
      // @track benifitList ;
      // @track bShowModal = false;
      // @api selectedProduct = '';
      @track errorMsg = '';
      @api recordId;
      @track recordIdOwnerId;
      @track userNameChoosen;
      @track disabledButton = false;
      disabledButtonStep1 = true;
      disabledButtonStep2 = true;
      @track currentStep = '1';
      @track lstSelected = [];
      @track totalRecord = 0;
      isShowSpinner = false;
    //   _isWarrantyOrder = false;
  
      doneTypingInterval = 800;
      typingTimer;
  
    //   handleOnStepClick(event) {
    //       this.currentStep = event.target.value;
    //   }
  
      connectedCallback() {
          this.getInitialData();
          this.setBoxes();
         
      }
   
      get isStepOne() {
          return this.currentStep === "1";
      }
   
      get isStepTwo() {
          return this.currentStep === "2";
      }
   
      get isEnableNext() {
          return this.currentStep != "3";
      }
   
      get isEnablePrev() {
          return this.currentStep != "1";
      }
   
     
    //   handleNext1(){
    //     let lstProductSelected = [];
    //     for(var key in this.lstSelected) {
    //         lstProductSelected.push(this.lstSelected[key].value);
    //     }
    //     if(this.currentStep == "1"){
    //         let rowindex = 1;
    //         let index = 0;
    //         getLstPromotionProductDTO({
    //             recordId: this.recordId,
    //             lstProduct: lstProductSelected
    //         }).then(apiResponse => {
    //             if(apiResponse.success) {
    //                 const result = apiResponse.result;
    //                 result.forEach(element => {
    //                     element.OrderBy = rowindex ++;
    //                     element.URLProduct = window.location.origin + '/' + element.Product;
    //                     element.index = index++;
    //                     // element.lstCampaignAsset.forEach(
    //                     //     item => {
    //                     //         item.UrlOrder = window.location.origin + '/' + item.Order__c;
    //                     // });
    //                     console.log('Product Name: ' + element.ProductName);
    //                 });
    //                 this.productList = result;
    //                 console.log(this.productList);
    //             } else {
    //                 this.showToastMessage(apiResponse.error, 'Error');
    //             }
    //         })
    //         .catch(error => {
    //             this.productList = '';
    //             if(error) {
    //                 if (Array.isArray(error.body)) {
    //                     this.errorMsg = error.body.map(e => e.message).join(', ');
    //                 } else if (typeof error.body.message === 'string') {
    //                     this.errorMsg = error.body.message;
    //                 }
    //             }
    //         })
    //         this.currentStep = "2";
    //     }
    // }
  
    handleNext2(){
        let lstProductSelected = [];
            for(var key in this.lstSelected) {
                lstProductSelected.push(this.lstSelected[key].value);
            }
        console.log(lstProductSelected);
        this.isShowSpinner = true;
        setTimeout(() => {
            savePromotionProductBike({
                lstProductDTO : lstProductSelected,
                recordId : this.recordId
            }).then(apiResponse => {
                this.isShowSpinner = false;
                if(apiResponse.success) {
                    this.showToastMessage('Save successfully!', 'success');
                    this.closeQuickAction();
                    this.dispatchEvent(new CustomEvent('recordChange'));
                } else {
                    this.showToastMessage(apiResponse.error, 'Error');
                }
            })
            .catch(error => {
                this.isShowSpinner = false;
                this.productList = '';
                if(error) {
                    if (Array.isArray(error.body)) {
                        this.errorMsg = error.body.map(e => e.message).join(', ');
                    } else if (typeof error.body.message === 'string') {
                        this.errorMsg = error.body.message;
                    }
                }
            })
            }, 50);
    }
   
      handlePrev(){
          if(this.currentStep = "2"){
              this.currentStep = "1";
          }
      }
  
      @track items = []; //this holds the array for records with value & label
      @track error;
      @track value;
      @track selectedList;
      @track createdMap = new Map();

      changeDiscount(event) {
        const valueInput = event.target.value;
        // based on selected row getting values of the contact  
        this.createdMap.get(event.target.dataset.id).Discount = valueInput;
       
        for(let key in this.items) {
            if(this.items[key].value.Id == event.target.dataset.id) {
                this.items[key].value.Discount = valueInput;
                break;
            }
        }
        for (let key in this.lstSelected){
            if(this.lstSelected[key].value.Id == event.target.dataset.id) {
                this.lstSelected[key].value.Discount = valueInput;
                break;
            }
        }
    }
      getInitialData(){
        let rowIndex = 1;
        getInitialData({
            recordId: this.recordId
        }).then(apiResponse => {
            if(apiResponse.success) {
                var mapData = [];
                const data = apiResponse.result;
                data.forEach(element => {
                    element.URLProduct2 = window.location.origin + '/' + element.Id;
                    element.OrderBy = rowIndex ++;
                    // element.UnitPriceVND = element.Price.toLocaleString('it-IT', {style : 'currency', currency : 'VND'});
                    mapData.push({value: element, key:element.Id});
                    if (element.IsChecked === true){
                        this.lstSelected.push({value: element, key:element.Id});
                    }
                });
                this.items = mapData;
                
                for (let i = 0; i < mapData.length; i++) {
                    this.createdMap.set(mapData[i].key, mapData[i].value);
                }
                // console.log(this.createdMap.get('01tO0000007GXeAIAW').ProductName);
                this.totalRecord = this.items ? this.items.length : 0;
                this.totalNumberSelected = this.lstSelected.length > 0 ? this.lstSelected.length : 0;
                if (this.lstSelected.length > 0){
                    this.disabledButtonStep1 = false;
                  }
            } else {
                this.showToastMessage(apiResponse.error, 'Error');
            }
        })
        .catch(error => {
            this.items = '';
            if(error) {
                if (Array.isArray(error.body)) {
                    this.errorMsg = error.body.map(e => e.message).join(', ');
                } else if (typeof error.body.message === 'string') {
                    this.errorMsg = error.body.message;
                }
            }
        })
    }
  
    handleSearch() {
        let rowindex = 1;
        const element = this.template.querySelector('[data-id="searchProd"]');
    
        getProductBySearchString({
            searchString  : element.value,
            recordId : this.recordId
        }).then(apiResponse => {
            if(apiResponse.success) {        
                var mapData = [];
                const data = apiResponse.result;
                data.forEach(element => {
                    element.URLProduct2 = window.location.origin + '/' + element.Id;
                    element.OrderBy = rowindex ++;
                    mapData.push({value: element, key:element.Id});
                });
                this.items = mapData;

                for(let keyId in this.items) {
                    if(this.items[keyId].value.Id === this.createdMap.get(this.items[keyId].value.Id).Id) {
                        this.items[keyId].value.IsChecked = this.createdMap.get(this.items[keyId].value.Id).IsChecked;
                        this.items[keyId].value.Discount = this.createdMap.get(this.items[keyId].value.Id).Discount;
                        this.items[keyId].value.PromotionProductId = this.createdMap.get(this.items[keyId].value.Id).PromotionProductId;
                        this.items[keyId].value.PromotionProductItem = this.createdMap.get(this.items[keyId].value.Id).PromotionProductItem;
                    }
                }
                // for(let key in this.lstSelected) {
                //     for(let keyId in this.items) {
                //         if(this.items[keyId].value.Id === this.lstSelected[key].value.Id) {
                //             this.items[keyId].value.IsChecked = this.lstSelected[key].value.IsChecked;
                //             this.items[keyId].value.Discount = this.lstSelected[key].value.Discount;
                //             this.items[keyId].value.PromotionProductId = this.lstSelected[key].value.PromotionProductId;
                //             break;
                //         }
                //     }
                // }
                this.totalRecord = this.items ? this.items.length : 0;
                
            } else {
                this.showToastMessage(apiResponse.error, 'Error');
            }
        })
        .catch(error => {
            this.productList = '';
            if(error) {
                if (Array.isArray(error.body)) {
                    this.errorMsg = error.body.map(e => e.message).join(', ');
                } else if (typeof error.body.message === 'string') {
                    this.errorMsg = error.body.message;
                }
            }
        }) 
    }
  
      closeQuickAction() {
          const closeQA = new CustomEvent('close');
          // Dispatches the event.
          this.dispatchEvent(closeQA);
      }
  
  
      setBoxes(event){
        const selectedRows = this.template.querySelectorAll('lightning-input');
        this.disabledButtonStep1 = true;
        var flagExitsLstSelected = false;
        // based on selected row getting values of the contact  
        for(let key in this.items) {
            if(flagExitsLstSelected) {
                break;
            }
            if(this.items[key].key === event.target.dataset.id) {
                for(let keySelect in this.lstSelected) {
                    if(this.lstSelected[keySelect].value.Id === event.target.dataset.id) {
                        if(!event.target.checked) {
                            this.items[key].IsChecked = false;
                            this.createdMap.get(this.items[key].value.Id).IsChecked = false;
                            this.lstSelected.splice(keySelect, 1);
                            console.log(this.lstSelected);    
                        }
                        console.log(this.lstSelected);
                        flagExitsLstSelected = true;
                        break;
                    }
                }
                if(!flagExitsLstSelected) {
                    if(event.target.checked) {
                        this.items[key].value.IsChecked = true;
                        this.createdMap.get(this.items[key].value.Id).IsChecked = true;
                        this.lstSelected.push({value: this.items[key].value, key:this.items[key].key});
                        break;
                    } else {
                        this.items[key].value.IsChecked = false;
                        this.createdMap.get(this.items[key].value.Id).IsChecked = false;
                    }
                }
            }
        }
        if(this.lstSelected.length > 0) {
            let rowIndex = 1;
            for(let key in this.lstSelected) {
                this.lstSelected[key].value.number = rowIndex++;
            }
            this.disabledButtonStep1 = false;
        }
        this.totalNumberSelected = this.lstSelected.length > 0 ? this.lstSelected.length : 0;
        console.log(this.lstSelected);
    }

  
      @track totalNumberSelected = 0;
      @track viewSelected = false;
  
      viewResultSelected() {
          if(this.viewSelected) {
              this.viewSelected = false;
          } else {
              this.viewSelected = true;
          }
      }
  
  
  
      showToastMessage(msg, type) {
          this.dispatchEvent(
              new ShowToastEvent({
                  variant: type,
                  message: msg
              })
          );
      }
}