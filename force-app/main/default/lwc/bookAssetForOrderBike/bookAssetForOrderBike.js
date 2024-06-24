import { LightningElement ,api, wire, track} from 'lwc';      
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createBookAsset from '@salesforce/apex/BookAssetForOrderBikeController.createBookAsset';
import getWarehouseInventoryByDODL from '@salesforce/apex/BookAssetForOrderBikeController.getWarehouseInventoryByDODL';
export default class BookAssetForOrderBike extends LightningElement {
    @api productList = [];
    @track benifitList ;
    @track bShowModal = false;
    @api selectedProduct = '';
    @track errorMsg = '';
    @api recordId;
    @track recordIdWarehouse;
     disabledButton = true;
    @api lstStrPriceBook;
    @track totalRecord = 0;
    
    isShowSpinner = false;

    handleOnStepClick(event) {
        this.currentStep = event.target.value;
    }

    connectedCallback() {
        this.getWarehouseInventoryByDODL();
    }
 
    getWarehouseInventoryByDODL(){
        let rowindex = 1;
        let index = 0;
        getWarehouseInventoryByDODL({
            recordId: this.recordId
        }).then(apiResponse => {
            if(apiResponse.success) {
                const result = apiResponse.result;
                result.forEach(element => {
                    element.URLWarehouse = window.location.origin + '/' + element.Id;
                    element.OrderBy = rowindex ++;
                    element.URLProduct = window.location.origin + '/' + element.Product2Id;
                    //element.UnitPriceVND = element.Price >= 0 ? element.Price.toLocaleString('it-IT', {style : 'currency', currency : 'VND'}) : '0 VND';
                    element.index = index++;
                    element.Ischecked = false;
                    // element.lstCampaignAsset.forEach(
                    //     item => {
                    //         item.UrlOrder = window.location.origin + '/' + item.Order__c;
                    // });
                });
                this.productList = result;
                this.totalRecord = this.productList.length > 0 ? this.productList.length : 0;
                console.log(this.productList);
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

    

    createBookAsset(){
        this.isShowSpinner = true;
        setTimeout(() => {
            createBookAsset({
                recordId: this.recordId,
                recordIdWarehouse: this.recordIdWarehouse,
                objObjWareHouseDTO : this.lstStrPriceBook
            }).then(apiResponse => {
                this.isShowSpinner = false;
                if(apiResponse.success) {
                    this.showToastMessage('Save successfully!', 'success');
                    this.closeQuickAction();
                    location.reload();
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


    // handleSearch() {
    //     let rowindex = 1;
    //     const element = this.template.querySelector('[data-id="searchProd"]');
    //     getPricebookPCABySearchString({
    //         recordId: this.recordId,
    //         searchString  : element.value
    //     }).then(apiResponse => {
    //         if(apiResponse.success) {
    //             const data = apiResponse.result;
    //             data.forEach(element => {
    //                 element.URLProduct2 = window.location.origin + '/' + element.Id;
    //                 element.OrderBy = rowindex ++;
    //                 element.UnitPriceVND = element.Price.toLocaleString('it-IT', {style : 'currency', currency : 'VND'});
    //             });
    //             this.items = data;
    //             for(let i = 0; i < this.items.length; i++) {
    //                 for(let j = 0; j < this.lstStrPriceBook.length; j++) {
    //                     if(this.items[i].Id == this.lstStrPriceBook[j].Id && this.lstStrPriceBook[j].Ischecked) {
    //                         this.items[i].Ischecked = true;
    //                     }
    //                 }
    //             }
    //             console.log(this.items);
    //             this.totalRecord = this.items ? this.items.length : 0;
                
    //         } else {
    //             this.showToastMessage(apiResponse.error, 'Error');
    //         }
    //     })
    //     .catch(error => {
    //         this.productList = '';
    //         if(error) {
    //             if (Array.isArray(error.body)) {
    //                 this.errorMsg = error.body.map(e => e.message).join(', ');
    //             } else if (typeof error.body.message === 'string') {
    //                 this.errorMsg = error.body.message;
    //             }
    //         }
    //     }) 
    // }

    closeQuickAction() {
        const closeQA = new CustomEvent('close');
        // Dispatches the event.
        this.dispatchEvent(closeQA);
    }


    setBoxes(event){
        this.disabledButton = true;    
        this.lstStrPriceBook = [];
        this.recordIdWarehouse = '';
        const boxes = this.template.querySelectorAll('lightning-input');
        boxes.forEach(box => box.checked = event.target.name === box.name);
        for(let i = 0; i < boxes.length; i++) {
            if(boxes[i].checked) {
                this.disabledButton = false;
                break;
            }
        }
        for(let j = 0; j < this.productList.length; j++) {
            for(let i = 0; i < boxes.length; i++) {
                if(boxes[i].type == 'checkbox' 
                    && this.productList[j].Id == boxes[i].name) {
                    if(boxes[i].checked) {
                        this.recordIdWarehouse = boxes[i].name;
                        this.lstStrPriceBook = this.productList[j];
                    }
                }
            }  
        }
        console.log('this.lstStrPriceBook');
        console.log(this.lstStrPriceBook);
        console.log(this.recordIdWarehouse);
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