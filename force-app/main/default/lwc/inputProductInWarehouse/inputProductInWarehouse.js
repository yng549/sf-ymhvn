import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getTranHeaderByRecordId from '@salesforce/apex/addProductInTransactionHeader.getTranHeaderByRecordId';
import getInitProduct from '@salesforce/apex/addProductInTransactionHeader.getInitProduct';
import lookUp from '@salesforce/apex/addProductInTransactionHeader.search';
import setBatchForProductSeletected from '@salesforce/apex/addProductInTransactionHeader.setBatchForProductSeletected';
import getProductSearchString from '@salesforce/apex/addProductInTransactionHeader.getProductSearchString';
import insertTransactionItem from '@salesforce/apex/addProductInTransactionHeader.insertTransactionItem';

export default class InputProductInWarehouse extends LightningElement {
    @api recordId;
    currentStep = '1';
    disabledButtonStep1 = true;
    disabledButtonStep2 = true;
    totalRecord = 0;
    totalNumberSelected = 0;
    viewSelected = false;
    errorMsg;
    @track lstProductAll = [];
    @track productListSeleted = [];
    @track lstStrPriceBook   = [];
    @api isShowSpinner = false;
    dataTranHeader;
    flagDataHeder=false;
    strFromWarehouse='';

    async connectedCallback() {
        await this.getTransactionHeaderByRecordId();
        await this.getInitProduct();
    }

    getTransactionHeaderByRecordId(){
        this.dataTranHeader = '';
        getTranHeaderByRecordId({
            recordId : this.recordId
        }).then(apiResponse => {
            if(apiResponse.success) {
                this.flagDataHeder = true;
                this.dataTranHeader = apiResponse.result;
            } else {
                this.showToastMessage(apiResponse.error, 'Error');
            }
        })
        .catch(error => {
            this.dataTranHeader = '';
            if(error) {
                if (Array.isArray(error.body)) {
                    this.errorMsg = error.body.map(e => e.message).join(', ');
                } else if (typeof error.body.message === 'string') {
                    this.errorMsg = error.body.message;
                }
            }
        })
    }

    getInitProduct(){
        let rowIndex = 1;
        getInitProduct({
            recordId: this.recordId
        }).then(apiResponse => {
            if(apiResponse.success) {
                const data = apiResponse.result;
                data.forEach(element => {
                    element.URLProduct2 = window.location.origin + '/' + element.Id;
                    element.OrderBy = rowIndex ++;
                });
                this.items = data;
                this.viewSelected = true;
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
    doneTypingInterval = 1000;
    typingTimer;
    handleSearch() {
        clearTimeout(this.typingTimer);
        this.typingTimer = setTimeout(() => {
            let rowindex = 1;
            const element = this.template.querySelector('[data-id="searchProd"]');
            getProductSearchString({
                searchString  : element.value,
                recordId : this.recordId
            }).then(apiResponse => {               
                if(apiResponse.success) {
                    const data = apiResponse.result;
                    data.forEach(element => {
                        element.URLProduct2 = window.location.origin + '/' + element.Id;
                        element.OrderBy = rowindex ++;
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

    handleChange(event) {
        for(var i=0; i< this.productListSeleted.length; i++) {
            if(event.target.dataset.id === this.productListSeleted[i].ProductId) {
                if(event.target.dataset.name === 'Quantity') {
                    this.productListSeleted[i].Quantity = event.target.value;

                } else if(event.target.dataset.name === 'OptionBatchOrSerial') {
                    this.productListSeleted[i].StrBatchOrSerial = event.target.value;

                } else if(event.target.dataset.name === 'BatchNumber') {
                    this.productListSeleted[i].BatchNumber = event.target.value;
                    
                } else if(event.target.dataset.name === 'SerialNumber') {
                    this.productListSeleted[i].SerialNumber = event.target.value;
                }
                else if(event.target.dataset.name === 'PriceCost') {
                    this.productListSeleted[i].PriceCost = event.target.value;
                }
                else if(event.target.dataset.name === 'VAT') {
                    this.productListSeleted[i].VAT = event.target.value;
                }
                else if(event.target.dataset.name === 'Note') {
                    this.productListSeleted[i].Note = event.target.value;
                }
            }
        }
        console.log(this.productListSeleted);
    }

    handleNext1(){
        this.productListSeleted = '';
        if(this.currentStep == "1"){
            let rowindex = 1;
            let index = 0;
            setBatchForProductSeletected({
                lstObjProductDTO: this.lstStrPriceBook
            }).then(apiResponse => {
                if(apiResponse.success) {
                    const result = apiResponse.result;
                    result.forEach(element => {
                        let options = [];
                        element.OrderBy = rowindex ++;
                        element.URLProduct = window.location.origin + '/' + element.ProductId;
                        element.index = index++;
                        if (this.dataTranHeader.From_Warehouse_Location__c){
                            element.Max = element.QoH;
                        }else{
                            element.Max = 9999;
                        }
                        for(var key in element.BatchOrSerial){
                            let option = {
                                label: element.BatchOrSerial[key],
                                value: element.BatchOrSerial[key]
                            };
                            options.push(option);
                        }
                        element.options = options;
                    });
                    this.productListSeleted = result;
                    console.log(this.productListSeleted);
                } else {
                    this.showToastMessage(apiResponse.error, 'Error');
                }
            })
            .catch(error => {
                this.productListSeleted = '';
                if(error) {
                    if (Array.isArray(error.body)) {
                        this.errorMsg = error.body.map(e => e.message).join(', ');
                    } else if (typeof error.body.message === 'string') {
                        this.errorMsg = error.body.message;
                    }
                }
            })
            this.currentStep = "2";
        }
    }


    handleNext2(){
        this.isShowSpinner = true;
        setTimeout(() => {
            insertTransactionItem({
                lstWarehouseDTO : this.productListSeleted,
                recordId: this.recordId
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
            }, 200);
    }

    setBoxes(event){
        var flagExitsLstSelected = false;
        this.disabledButtonStep1 = true;
        // based on selected row getting values of the contact
        for(let j = 0; j < this.items.length; j++) {
            if(flagExitsLstSelected) {
                break;
            }
            if(this.items[j].Id == event.target.dataset.id) {
                for(let k = 0; k < this.lstStrPriceBook.length; k++) {
                    if(event.target.dataset.id == this.lstStrPriceBook[k].Id) {
                        if(!event.target.checked) {
                            this.items[j].Ischecked = event.target.checked;
                            this.lstStrPriceBook.splice(k, 1);
                        }
                        flagExitsLstSelected = true;
                        break;
                    }
                }
                if(!flagExitsLstSelected) {
                    this.items[j].Ischecked = event.target.checked;
                    if(event.target.checked) {
                        this.lstStrPriceBook.push(this.items[j]);
                    }
                    break;
                }
            }
        }
        console.log(this.lstStrPriceBook);
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

    @track viewSelected = false;

    viewResultSelected() {
        if(this.viewSelected) {
            this.viewSelected = false;
        } else {
            this.viewSelected = true;
        }
    }

    closeQuickAction() {
        const closeQA = new CustomEvent('close');
        // Dispatches the event.
        this.dispatchEvent(closeQA);
    }


    handleOnStepClick(event) {
        this.currentStep = event.target.value;
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

 
    handlePrev(){
        if(this.currentStep = "2"){
            this.currentStep = "1";
        }
    }




    ///LOOKUP SEARCH
    @api objName = 'Warehouse_Location__c';
    @api iconName;
    @api filter = '';
    @api searchPlaceholder='Search';

    @track selectedName;
    @track records;
    @track isValueSelected;
    @track blurTimeout;

    searchTerm;
    //css
    @track boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
    @track inputClass = '';

    @wire(lookUp, {searchTerm : '$searchTerm', myObject : '$objName', filter : '$filter'})
    wiredRecords({ error, data }) {
        if (data) {
            this.error = undefined;
            this.records = data;
        } else if (error) {
            this.error = error;
            this.records = undefined;
        }
    }


    handleClick() {
        this.searchTerm = '';
        this.inputClass = 'slds-has-focus';
        this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus slds-is-open';
    }

    onBlur() {
        this.blurTimeout = setTimeout(() =>  {this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus'}, 300);
    }

    onSelect(event) {
        let selectedId = event.currentTarget.dataset.id;
        let selectedName = event.currentTarget.dataset.name;
        const valueSelectedEvent = new CustomEvent('lookupselected', {detail:  selectedId });
        this.dispatchEvent(valueSelectedEvent);
        this.isValueSelected = true;
        this.selectedName = selectedName;
        if(this.blurTimeout) {
            clearTimeout(this.blurTimeout);
        }
        this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
    }

    handleRemovePill() {
        this.isValueSelected = false;
    }

    onChange(event) {
        this.searchTerm = event.target.value;
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