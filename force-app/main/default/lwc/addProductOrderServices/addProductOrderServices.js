import { LightningElement ,api, wire, track} from 'lwc';      
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getInitalPricebookPCA from '@salesforce/apex/AddProductServicesOrder.getInitalPricebookPCA';
import getPricebookPCABySearchString from '@salesforce/apex/AddProductServicesOrder.getPricebookPCABySearchString';
import createOrderProductPCA from '@salesforce/apex/AddProductServicesOrder.createOrderProductPCA';
export default class AddProductOrderPCA extends LightningElement {
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
    @track lstStrPriceBook = [];
    @track totalRecord = 0;
    isShowSpinner = false;
    _isWarrantyOrder = false;

    doneTypingInterval = 800;
    typingTimer;

    handleOnStepClick(event) {
        this.currentStep = event.target.value;
    }

    connectedCallback() {
        this.getInitalPricebookPCA();
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
 
 
    handleNext1(){
        if(this.currentStep == "1"){
            let rowindex = 1;
            let index = 0;
            const result = this.lstStrPriceBook;
            result.forEach(element => {
                let symtomOptions = [];
                element.URLWarehouse = window.location.origin + '/' + element.Id;
                element.OrderBy = rowindex ++;
                element.URLProduct = window.location.origin + '/' + element.Product2Id;
                element.UnitPriceVND = element.Price.toLocaleString('it-IT', {style : 'currency', currency : 'VND'});
                element.index = index++;
                debugger;
                if (Array.isArray(element.symtomconditions) && element.symtomconditions.length > 0) {
                    this._isWarrantyOrder = true;
                    element.symtomconditions.forEach(key => {
                        symtomOptions.push({
                            label : key.Symptom__r['Name'],
                            value: key.Id
                        })
                    });
                    element.controllingValues = symtomOptions;
                }
            });
            this.productList = result;
            this.currentStep = "2";
        }
    }

    handleSymtomChange(event) {
        const valueInput = event.target.value;
        // based on selected row getting values of the contact
        for(let j = 0; j < this.productList.length; j++) {
            if(this.productList[j].index == event.target.dataset.id) {
                this.productList[j].idSymtonmotor = valueInput;
                break;
            }
        }
      }

    handleNext2(){
        this.isShowSpinner = true;
        setTimeout(() => {
            createOrderProductPCA({
                recordId: this.recordId,
                lstProductEntries : this.productList
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

    getInitalPricebookPCA(){
        let rowIndex = 1;
        getInitalPricebookPCA({
            recordId: this.recordId,
        }).then(apiResponse => {
            if(apiResponse.success) {
                const data = apiResponse.result;
                data.forEach(element => {
                    element.URLProduct2 = window.location.origin + '/' + element.Id;
                    element.OrderBy = rowIndex ++;
                    element.UnitPriceVND = element.Price.toLocaleString('it-IT', {style : 'currency', currency : 'VND'});
                });
                this.items = data.sort();
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


    handleSearch(event) {
        clearTimeout(this.typingTimer);
        let value = event.target.value;

        this.typingTimer = setTimeout(() => {
            let rowindex = 1;
            const element = this.template.querySelector('[data-id="searchProd"]');
            getPricebookPCABySearchString({
                recordId: this.recordId,
                searchString  : element.value ? element.value : null
            }).then(apiResponse => {
                if(apiResponse.success) {
                    const data = apiResponse.result;
                    data.forEach(element => {
                        element.URLProduct2 = window.location.origin + '/' + element.Id;
                        element.OrderBy = rowindex ++;
                        element.UnitPriceVND = element.Price.toLocaleString('it-IT', {style : 'currency', currency : 'VND'});
                    });
                    this.items = data;
                    for(let i = 0; i < this.items.length; i++) {
                        for(let j = 0; j < this.lstStrPriceBook.length; j++) {
                            if(this.items[i].Id == this.lstStrPriceBook[j].Id && this.lstStrPriceBook[j].Ischecked) {
                                this.items[i].Ischecked = true;
                            }
                        }
                    }
                    console.log(this.items);
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

        }, this.doneTypingInterval);
    }

    closeQuickAction() {
        const closeQA = new CustomEvent('close');
        // Dispatches the event.
        this.dispatchEvent(closeQA);
    }


    setBoxes(){
        const selectedRows = this.template.querySelectorAll('lightning-input');
        this.disabledButtonStep1 = true;
        // based on selected row getting values of the contact
        for(let i = 0; i < selectedRows.length; i++) {
            if(selectedRows[i].type === 'checkbox') {
                for(let j = 0; j < this.items.length; j++) {
                    if(this.items[j].Id == selectedRows[i].dataset.id) {
                        var flagExitsLstSelected = false;
                        for(let k = 0; k < this.lstStrPriceBook.length; k++) {
                            if(selectedRows[i].dataset.id == this.lstStrPriceBook[k].Id) {
                                if(!selectedRows[i].checked) {
                                    this.items[j].Ischecked = false;
                                    this.lstStrPriceBook.splice(k);
                                }
                                console.log(this.lstStrPriceBook);
                                flagExitsLstSelected = true;
                                break;
                            }
                        }
                        if(!flagExitsLstSelected) {
                            if(selectedRows[i].checked) {
                                this.items[j].Ischecked = true;
                                this.lstStrPriceBook.push(this.items[j]);
                            } else {
                                this.items[j].Ischecked = false;
                            }
                        }
                    }
                }
            }
        }
        if(this.lstStrPriceBook.length > 0) {
            let rowIndex = 1;
            this.lstStrPriceBook.forEach(e =>{
                e.number = rowIndex++;
            });
            this.disabledButtonStep1 = false;
        }
        this.totalNumberSelected = this.lstStrPriceBook.length > 0 ? this.lstStrPriceBook.length : 0;
        console.log(this.lstStrPriceBook);
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