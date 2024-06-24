import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getWarehouseInitByPromotion from '@salesforce/apex/redeemVoucherAfterBuyBike.getWarehouseInitByPromotion';
import createOrder from '@salesforce/apex/redeemVoucherAfterBuyBike.createOrder';

export default class RedeemVoucherAfterBuyBike extends LightningElement {
    @track benifitList ;
    @track bShowModal = false;
    @api selectedProduct = '';
    @track errorMsg = '';
    @api recordId;
    @track amountSelect = 0;
    @track disabledButton = false;
    @track lstStrPriceBook = [];
    @track totalRecord = 0;
    @track searchKey = '';
    isShowSpinner = false;
    @track isData = false;
    @track isDisabled =true;
    connectedCallback() {
        this.getWarehouseInitByPromotion();
    }
 
    

    handleNext2(){
        this.isShowSpinner = true;
        setTimeout(() => {
            createOrder({
                lstWarehouseDTO : this.lstStrPriceBook,
                recordId: this.recordId,
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
                this.lstStrPriceBook = '';
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

    changeNumberQuantity(event) {
        this.amountSelect = 0;
        const valueInput = event.target.value;
        this.isDisabled = true;
        // based on selected row getting values of the contact
        for(let j = 0; j < this.items.lstWarehouseDTO.length; j++) {
            if(this.items.lstWarehouseDTO[j].Id == event.target.dataset.id) {
                this.items.lstWarehouseDTO[j].QuantityInput = valueInput;
                break;
            }
        }
        this.lstStrPriceBook.forEach(e =>{
            this.amountSelect += e.Price*e.QuantityInput;
        });
        if(this.amountSelect > this.items.TotalAmount) {
            this.isDisabled = true;
            this.lstStrPriceBook.forEach(e =>{
                for(let i = 0; i < this.items.lstWarehouseDTO.length; i++) {
                    if(this.items.lstWarehouseDTO[i].Id != e.Id && !this.items.lstWarehouseDTO[i].Ischecked) {
                        this.items.lstWarehouseDTO[i].isDisabled = true;
                    }
                }
            });
        } else {
            if(this.lstStrPriceBook.length) {
                this.isDisabled = false;
                this.lstStrPriceBook.forEach(e =>{
                    for(let i = 0; i < this.items.lstWarehouseDTO.length; i++) {
                        if(this.items.lstWarehouseDTO[i].Id != e.Id && !this.items.lstWarehouseDTO[i].Ischecked) {
                            this.items.lstWarehouseDTO[i].isDisabled = false;
                        }
                    }
                });
            } else {
                for(let i = 0; i < this.items.lstWarehouseDTO.length; i++) {
                    if(this.items.lstWarehouseDTO[i].isDisabled) {
                        this.items.lstWarehouseDTO[i].isDisabled = false;
                    }
                }
            }
            
        }
    }
   
    @track error;
    @track value;
    @track selectedList;

    getWarehouseInitByPromotion(){
        let rowIndex = 1;
        getWarehouseInitByPromotion({
            recordId: this.recordId,
            strName: this.searchKey
        }).then(apiResponse => {
            if(apiResponse.success) {
                const data = apiResponse.result;
                if(data.lstWarehouseDTO) {
                    data.lstWarehouseDTO.forEach(element => {
                        element.URLProduct2 = window.location.origin + '/' + element.Id;
                        element.OrderBy = rowIndex ++;
                    });
                }
                this.items = data;
                this.totalRecord = this.items.lstWarehouseDTO ? this.items.lstWarehouseDTO.length : 0;
                if(this.totalRecord > 0) {
                    this.isData = true;
                }
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
            this.searchKey = element.value;
            getWarehouseInitByPromotion({
                recordId: this.recordId,
                strName  : this.searchKey
            }).then(apiResponse => {
                if(apiResponse.success) {
                    const data = apiResponse.result;
                    this.items = data;
                    if(this.items.lstWarehouseDTO) {
                        this.items.lstWarehouseDTO.forEach(element => {
                            element.URLProduct2 = window.location.origin + '/' + element.Id;
                            element.OrderBy = rowindex ++;
                        });
                    }
                    
                    
                    for(let i = 0; i < this.items.lstWarehouseDTO.length; i++) {
                        for(let j = 0; j < this.lstStrPriceBook.length; j++) {
                            if(this.items.lstWarehouseDTO[i].Id == this.lstStrPriceBook[j].Id && this.lstStrPriceBook[j].Ischecked) {
                                this.items.lstWarehouseDTO[i].Ischecked = true;
                            }
                        }
                    }
                    console.log(this.items);
                    this.totalRecord = this.items.lstWarehouseDTO ? this.items.lstWarehouseDTO.length : 0;
                    
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

    @track items = []; //this holds the array for records with value & label
    setBoxes(event){
        this.isDisabled = true;
        this.amountSelect = 0;
        const selectedRows = [...this.template.querySelectorAll('lightning-input')].filter(e => 
            e.dataset.id === event.target.value && e.type === 'checkbox');
        this.disabledButtonStep1 = true;
        var flagExitsLstSelected = false;
        // based on selected row getting values of the contact
        if(selectedRows[0]) {
            for(let j = 0; j < this.items.lstWarehouseDTO.length; j++) {
                if(this.items.lstWarehouseDTO[j].Id == selectedRows[0].dataset.id) {
                    for(let k = 0; k < this.lstStrPriceBook.length; k++) {
                        if(selectedRows[0].dataset.id == this.lstStrPriceBook[k].Id) {
                            if(!selectedRows[0].checked) {
                                this.items.lstWarehouseDTO[j].Ischecked = false;
                                this.items.lstWarehouseDTO[j].QuantityInput = 1;
                                this.lstStrPriceBook.splice(k);
                            }
                            console.log(this.lstStrPriceBook);
                            flagExitsLstSelected = true;
                            break;
                        }
                    }
                    if(!flagExitsLstSelected) {
                        if(selectedRows[0].checked) {
                            this.items.lstWarehouseDTO[j].Ischecked = true;
                            this.lstStrPriceBook.push(this.items.lstWarehouseDTO[j]);
                        } else {
                            this.items.lstWarehouseDTO[j].Ischecked = false;
                            this.items.lstWarehouseDTO[j].QuantityInput = 1;
                        }
                    }
                    if(flagExitsLstSelected) {
                        break;
                    }
                }
            }
        }
        
        if(this.lstStrPriceBook.length > 0) {
            let rowIndex = 1;
            this.lstStrPriceBook.forEach(e =>{
                this.amountSelect += e.Price*e.QuantityInput;
                e.number = rowIndex++;
            });
            this.disabledButtonStep1 = false;
        }
        this.totalNumberSelected = this.lstStrPriceBook.length > 0 ? this.lstStrPriceBook.length : 0;
        console.log('this.amountSelect:'+this.amountSelect);
        if(this.amountSelect > this.items.TotalAmount) {
            this.lstStrPriceBook.forEach(e =>{
                for(let i = 0; i < this.items.lstWarehouseDTO.length; i++) {
                    if(this.items.lstWarehouseDTO[i].Id != e.Id && !this.items.lstWarehouseDTO[i].Ischecked) {
                        this.items.lstWarehouseDTO[i].isDisabled = true;
                    }
                }
            });
        } else {
            if(this.lstStrPriceBook.length) {
                this.isDisabled = false;
                this.lstStrPriceBook.forEach(e =>{
                    for(let i = 0; i < this.items.lstWarehouseDTO.length; i++) {
                        if(this.items.lstWarehouseDTO[i].Id != e.Id && !this.items.lstWarehouseDTO[i].Ischecked) {
                            this.items.lstWarehouseDTO[i].isDisabled = false;
                        }
                    }
                });
            } else {
                for(let i = 0; i < this.items.lstWarehouseDTO.length; i++) {
                    if(this.items.lstWarehouseDTO[i].isDisabled) {
                        this.items.lstWarehouseDTO[i].isDisabled = false;
                    }
                }
            }
            
        }
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