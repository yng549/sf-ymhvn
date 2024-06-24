import { LightningElement ,api, wire, track} from 'lwc';      
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getProduct from '@salesforce/apex/createServicePackageForOrder.retriveProducts';
import getPickListPriceBookEntry from '@salesforce/apex/createServicePackageForOrder.getPickListPriceBookEntry';
import createOrderItem from '@salesforce/apex/createServicePackageForOrder.createOrderItem';
export default class AddProductForOrderServicePakage extends LightningElement {
    @track productList ;
    @track benifitList ;
    @track bShowModal = false;
    @api selectedProduct = '';
    @track errorMsg = '';
    @api recordId;
    @track recordIdPriceBook;
    @track disabledButton = false;
    disabledButtonStep1 = true;
    disabledButtonStep2 = true;
    @track currentStep = '1';
    @track lstStrPriceBook = [];
    isShowSpinner = false;

    handleOnStepClick(event) {
        this.currentStep = event.target.value;
    }

    connectedCallback() {
        this.pricebookList();
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
            let listMember = [];
            this.productList= [];
            getProduct({
                recordId: this.recordId,
                strIdPriceBook: this.recordIdPriceBook  
            }).then(apiResponse => {
                if(apiResponse.success) {
                    const result = apiResponse.result;
                    result.forEach(element => {
                        let member = { 
                            'Id': element.Id,
                            'Name': element.ProductName,
                            'ListPrice' : element.ListPrice,
                            'ProductCode' : element.ProductCode,
                            'URLProduct': window.location.origin + '/' + element.Id,
                            'OrderBy': rowindex ++,
                            'PricebookId' : element.PricebookId,
                            'hideBool' : element.hideBool,
                            'dtDate' : element.dtDate,
                            'lstProductSession' : element.lstProductDetailService
                        };
                        listMember.push(member);
                    });
                    this.productList = listMember;
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
            this.currentStep = "2";
        }
    }

    

    handleNext2(){
        this.isShowSpinner = true;
        setTimeout(() => {
            createOrderItem({
                recordId: this.recordId,
                lstStrPriceBookEntry : this.lstStrPriceBook,
                strIdPriceBook : this.recordIdPriceBook
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
            }, 200);
    }
 
    handlePrev(){
        if(this.currentStep = "2"){
            this.disabledButtonStep1 = true;
            this.currentStep = "1";
        }
    }

    @track items = []; //this holds the array for records with value & label
    @track error;
    @track value;

    pricebookList(){
        var lstPriceBook2 = [];
        getPickListPriceBookEntry().then(apiResponse => {
            if(apiResponse.success) {
                const data = apiResponse.result;
                data.forEach(element => {
                    var obj = {
                        value : element.Id,
                        label : element.Name
                    };
                    lstPriceBook2.push(obj)
                });
                this.items = lstPriceBook2;
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
    get pricebookOptions(){
        return this.items;
    }
    pricebookChange(event) {
        this.disabledButtonStep1 = true;
        if(event.detail.value) {
            this.recordIdPriceBook = event.detail.value;
            this.disabledButtonStep1 = false;
        }
    }

    

    hideAndShow(event) {
        let indx = event.target.dataset.recordId;
        if (this.productList) {
            let recs = JSON.parse(JSON.stringify(this.productList));
            recs[indx].hideBool = !recs[indx].hideBool;
            this.productList = recs;
            console.log('After Change ' + this.productList[indx].hideBool);
        }
        if (event.target.label === "-") {
            event.target.label = "+";
        } else {
            event.target.label = "-";
        }
    }

    changeDate() {
        const boxes = this.template.querySelectorAll('input');
        this.disabledButtonStep2 = true;
        for(let i = 0; i < this.productList.length; i++) {
            for(let j = 0; j < boxes.length; j++) {
                if(this.productList[i].PricebookId == boxes[j].name) {
                    this.productList[i].dtDate = boxes[j].value;
                }
            }   
        }
        this.setBoxes();
    }

    setBoxes(){
        const boxes = this.template.querySelectorAll('lightning-input');
        this.lstStrPriceBook = [];
        this.disabledButtonStep2 = true;
        for(let i = 0; i < boxes.length; i++) {
            if(boxes[i].checked) {
                this.disabledButtonStep2 = false;
            }
        }
        for(let j = 0; j < this.productList.length; j++) {
            for(let i = 0; i < boxes.length; i++) {
                if(boxes[i].checked && boxes[i].type == 'checkbox' 
                    && this.productList[j].PricebookId == boxes[i].name) {
                    this.lstStrPriceBook.push(this.productList[j]);
                }
            }  
        }
    }


    closeQuickAction() {
        const closeQA = new CustomEvent('close');
        // Dispatches the event.
        this.dispatchEvent(closeQA);
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