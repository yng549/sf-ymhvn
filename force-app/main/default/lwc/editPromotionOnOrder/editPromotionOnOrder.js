import { LightningElement ,api, wire, track} from 'lwc';      
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getInitViewEditPromotionItem from '@salesforce/apex/EditPromotionOnOrder.getInitViewEditPromotionItem';
import updateFieldPromotionItem from '@salesforce/apex/EditPromotionOnOrder.updateFieldPromotionItem';
import searchVoucherByKeyInput from '@salesforce/apex/EditPromotionOnOrder.searchVoucherByKeyInput';
import updateVoucherApplyPromotionItem from '@salesforce/apex/EditPromotionOnOrder.updateVoucherApplyPromotionItem';

export default class EditPromotionOnOrder extends LightningElement {
    @api productList ;
    @track benifitList ;
    @track bShowModal = false;
    @api selectedProduct = '';
    @track errorMsg = '';
    @api recordId;
    @track recordIdOwnerId;
    @track userNameChoosen;
    @track disabledButton = false;
    disabledButtonStep1 = true;
    disabledButtonStep2 = true;
    @track currentStep = '1';
    lstStrPriceBook = [];
    @track totalRecord = 0;
    
    isShowSpinner = false;

    handleOnStepClick(event) {
        this.currentStep = event.target.value;
    }

    connectedCallback() {
        this.getInitPromotionItem();
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
 
 
    isStep2 = false;
    handleNext1(){
        if(this.currentStep == "1"){
            if(this.objPromotionSelected) {
                if(this.objPromotionSelected.hasOwnProperty('RecordTypePromotion') && this.objPromotionSelected.RecordTypePromotion === "Default") {
                    this.handleNext2();
                } else {
                    this.currentStep = "2";
                    this.isStep2 = true;
                }
            } else if(this.vocherSearch) {
                this.updateVoucher();
            }
        }
    }


    updateVoucher() {
        this.isShowSpinner = true;
        setTimeout(() => {
            updateVoucherApplyPromotionItem({
                objVoucherDTO : this.vocherSearch,
                recordId : this.recordId
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
                if(error) {
                    if (Array.isArray(error.body)) {
                        this.errorMsg = error.body.map(e => e.message).join(', ');
                    } else if (typeof error.body.message === 'string') {
                        this.errorMsg = error.body.message;
                    }
                }
            })
            }, 500);
    }

    vocherSearch;
    handleFilter() {
        this.vocherSearch = '';
        this.disabledButtonStep1 = true;
        let data = [];
        this.objPromotionSelected = '';
        for(let key in this.items) {
            if(this.items[key].IsCheck) {
                this.items[key].IsCheck = false;
            }
        }
        if(this.objPromotionSelected) {
            this.disabledButtonStep1 = false;
        }
        const searchKey = this.template.querySelector("lightning-input[data-id='searchVoucher']");
        this.isShowSpinner = true;
        setTimeout(() => {
            searchVoucherByKeyInput({
                strSearchKey : searchKey.value
            }).then(apiResponse => {
                this.isShowSpinner = false;
                if(apiResponse.success) {
                    data.push(apiResponse.result);
                    data.forEach(e => {
                        e.UrlVoucher = window.location.origin + '/' + e.Id;
                    });
                    this.vocherSearch = data[0];
                    console.log(this.vocherSearch);
                } else {
                    this.showToastMessage(apiResponse.error, 'Error');
                }
            })
            .catch(error => {
                this.isShowSpinner = false;
                if(error) {
                    if (Array.isArray(error.body)) {
                        this.errorMsg = error.body.map(e => e.message).join(', ');
                    } else if (typeof error.body.message === 'string') {
                        this.errorMsg = error.body.message;
                    }
                }
            })
            }, 500);
    }

    handleNext2(){
        this.isShowSpinner = true;
        setTimeout(() => {
            updateFieldPromotionItem({
                recordId: this.recordId,
                recordSelected : this.objPromotionSelected.Id
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
                if(error) {
                    if (Array.isArray(error.body)) {
                        this.errorMsg = error.body.map(e => e.message).join(', ');
                    } else if (typeof error.body.message === 'string') {
                        this.errorMsg = error.body.message;
                    }
                }
            })
            }, 500);
    }

 
    handlePrev(){
        this.isStep2 = false;
        if(this.currentStep = "2"){
            this.currentStep = "1";
        }
    }

    items = []; //this holds the array for records with value & label
    @track error;
    @track value;
    @track selectedList;

    getInitPromotionItem(){
        let rowIndex = 1;
        getInitViewEditPromotionItem({
            recordId: this.recordId,
        }).then(apiResponse => {
            if(apiResponse.success) {
                const data = apiResponse.result;
                data.forEach(element => {
                    element.URLPromotionId = window.location.origin + '/' + element.Id;
                    element.OrderBy = rowIndex ++;
                    if(element.lstProductApplyDTO) {
                        element.lstProductApplyDTO.forEach(e => {
                            e.URLPromotionProduct = window.location.origin + '/' + e.objPromotionProduct.Id;
                        });
                    }
                });
                this.items = data;
                console.log(this.items);
                this.totalRecord = this.items ? this.items.length : 0;
                console.log(this.items);
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



    closeQuickAction() {
        const closeQA = new CustomEvent('close');
        // Dispatches the event.
        this.dispatchEvent(closeQA);
    }

    objPromotionSelected;
    setBoxes(event){
        this.objPromotionSelected = ''; 
        const boxes = this.template.querySelectorAll('lightning-input');
        boxes.forEach(box => box.checked = event.target.name === box.name);

        this.disabledButtonStep1 = true;
        // based on selected row getting values of the contact  
        for(let key in this.items) {
            if(event.target.dataset.id == this.items[key].Id) {
                if(this.items[key].lstPromotionProduct) {
                    this.items[key].IsCheck = event.target.checked;
                    this.objPromotionSelected = this.items[key];
                } else if(this.items[key].hasOwnProperty('RecordTypePromotion')) {
                    if(this.items[key].RecordTypePromotion === "Default") {
                        this.items[key].IsCheck = event.target.checked;
                        this.objPromotionSelected = this.items[key];
                    }
                }
                
            } else {
                if(this.items[key].IsCheck) {
                    this.items[key].IsCheck = false;
                }
            }
        }
        if(this.objPromotionSelected) {
            this.disabledButtonStep1 = false;
        }
        console.log(this.objPromotionSelected);
    }

    setBoxesVoucher(event) {
        this.disabledButtonStep1 = true;
        this.objPromotionSelected = '';
        this.vocherSearch.IsCheck = event.target.checked;
        if(this.vocherSearch.IsCheck) {
            this.disabledButtonStep1 = false;
        }
    }



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