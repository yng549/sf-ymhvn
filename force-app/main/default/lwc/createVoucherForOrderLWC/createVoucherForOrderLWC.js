import { LightningElement, track , api, wire} from 'lwc';
import createVoucher from '@salesforce/apex/CreateVoucherController.createVoucher';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCustomSettings from '@salesforce/apex/CreateVoucherController.getCustomSettings';
import getQuoteByOpportunityId from '@salesforce/apex/CreateVoucherController.getQuoteByOpportunityId';
export default class CreateVoucherForOrderLWC extends LightningElement {
    @api objPromotion;
    @api recordId;
    @track displayMessage = '';
    @track isLoading;
    @track selectOption = [{
        label: 'Case Status Implementation',
        value: 'Case Status Implementation'
    }];
    @track _helpMessage;
    @api strSubject;
    @api strEstimateTime;
    @track autoView = false;
    @track manualView = false;
    @track flagErrorManualInput = false;
    @track valueInputAutoDivide = 0;
    @track resultAutoDivide = 0;
    @track resultAutoDivideFlag = false;
    @track resultTolalManual = 0;
    @track flagResultTolalManual = false;
    @track amountDecimal = 0;
    @track intQuantityClone = 0;
    @track flagDisabledButtonSave = false;
    @track flagErrorManualInputLessTotal = false;
    @wire(getCustomSettings)
    myCustomSettings;
    errorMsg = '';
    @api objQuoteSyncing;
    get options() {
        return [
            { label: 'Automation Divide', value: 'Automation Divide' },
            { label: 'Manual Divide', value: 'Manual Divide' },
        ];
    }

    connectedCallback() {
        this.getQuoteByOpportunityId();
        console.log('this.objPromotion', JSON.stringify(this.objPromotion));
    }

    getQuoteByOpportunityId() {
        this.objQuoteSyncing = '';
        getQuoteByOpportunityId({
                strOpportuntiyID : this.objPromotion.OpportunityId
            }).then(apiResponse => {
                if(apiResponse.success) {
                    this.objQuoteSyncing = apiResponse.result;
                } else {
                    this.showToastMessage('Error', '', apiResponse.error);
                }
            })
            .catch(error => {
                this.objQuoteSyncing = '';
                if(error) {
                    if (Array.isArray(error.body)) {
                        this.errorMsg = error.body.map(e => e.message).join(', ');
                    } else if (typeof error.body.message === 'string') {
                        this.errorMsg = error.body.message;
                    }
                }
        })
    }



    handleOnChange(evt) {
        this.value = evt.target.value;
        if(this.value === 'Automation Divide') {
            this.autoView = true;
            this.manualView = false;
            this.flagDisabledButtonSave = false;
            this.itemList = [{
                id: 0
            }];
            this.resultTolalManual = 0;
            this.flagErrorManualInput = false;
            this.flagErrorManualInputLessTotal = false;
            this.flagResultTolalManual = false;
        } else if(this.value === 'Manual Divide') {
            this.displayMessage = '';
            this.autoView = false;
            this.manualView = true;
            this.flagDisabledButtonSave = false;    
            this.valueInputAutoDivide = 0;
            this.resultAutoDivideFlag = false;
            this.resultAutoDivide = 0;
        }
        // how to make the UI select Option one?
    }

    changeValueInputManualDivide(event) {
        this.resultTolalManual = 0;
        this.flagErrorManualInput = false;
        this.flagErrorManualInputLessTotal = false
        this.flagResultTolalManual = false;
        this.flagDisabledButtonSave = false;
        let element  = this.itemList;
        
        for(var i =0; i < element.length; i++) {
            if(parseInt(event.target.accessKey) == parseInt(element[i].id)) {
                element[i].value = event.target.value;
            }
            this.resultTolalManual += parseInt(element[i].value);
        }
        if(this.objQuoteSyncing.Voucher_Amount__c < this.resultTolalManual) {
            this.flagResultTolalManual = true;
            this.flagErrorManualInput = true;
        } else if(this.objQuoteSyncing.Voucher_Amount__c > this.resultTolalManual 
            && this.resultTolalManual > 0) {
            this.flagResultTolalManual = true;
            this.flagErrorManualInputLessTotal = true;
        } else if(this.objQuoteSyncing.Voucher_Amount__c == this.resultTolalManual 
            && this.resultTolalManual > 0){
            this.flagResultTolalManual = true;   
            this.flagDisabledButtonSave = true;
            
        }
    }

    changeValueInputAutoDivide(evt) {
        console.log('a');
        
        this.valueInputAutoDivide = evt.target.value;
        this.resultAutoDivideFlag = false;
        if(this.valueInputAutoDivide == 0 ||this.valueInputAutoDivide > this.myCustomSettings.data.Quantity__c) {
            this.displayMessage = 'The value input must be greater than 0 or less equal 10';
            this.flagDisabledButtonSave = false;
        } else if(this.valueInputAutoDivide > 0) {
            this.resultAutoDivide = Math.round(this.objQuoteSyncing.Voucher_Amount__c / this.valueInputAutoDivide);
            this.amountDecimal = this.resultAutoDivide;
            this.intQuantityClone = this.valueInputAutoDivide;
            console.log(this.amountDecimal);
            console.log(this.intQuantityClone);
            if(this.resultAutoDivide > 0) {
                this.displayMessage = '';
                this.flagDisabledButtonSave = true;
                this.resultAutoDivideFlag = true;
            }
        } 
    }

    


    keyIndex = 0;
    @track itemList = [
        {
            id: 0
        }
    ];

    addRow() {
        ++this.keyIndex;
        var newItem = [{ id: this.keyIndex , value: 0}];
        this.itemList = this.itemList.concat(newItem);
    }

    removeRow(event) {
        if (this.itemList.length >= 2) {
            for(var i =0; i < this.itemList.length; i++) {
                
                if(parseInt(this.itemList[i].id) == parseInt(event.target.accessKey)) {
                    console.log(parseInt(this.itemList[i].id));
                    console.log(parseInt(event.target.accessKey));
                    this.itemList.splice(i, 1);
                }
            }
            this.resultTolalManual = 0;
            this.flagErrorManualInput = false;
            this.flagResultTolalManual = false;
            let element  = this.itemList;
            for(var i =0; i < element.length; i++) {
                this.resultTolalManual += parseInt(element[i].value);
            }
            if(this.resultTolalManual > 0) {
                this.flagResultTolalManual = true
                if(this.objQuoteSyncing.Voucher_Amount__c < this.resultTolalManual) {
                    this.flagErrorManualInput = true;
                }
            }
        }
    }

    handleSubmit() {
        if(this.value === 'Automation Divide') {
            createVoucher({
                strRecordId: this.recordId,
                intQuantityClone: this.intQuantityClone,
                dcmAmountInput: this.amountDecimal
            }).then(response => {
              if (response && response.success) {
                this.showToastMessage('success', 'Success!', 'Save rule successfully.');
                const closeQA = new CustomEvent('close');
                // Dispatches the event.
                this.dispatchEvent(closeQA);
              } else {
                if (response && response.error) {
                  this.showToastMessage('error', '', response.error);
                } else {
                  this.showToastMessage('error', '', response.error);
                }
              }
              this.isLoading = false;
            }).catch(e => {
              this.showToastMessage('error', '', 'Fail save condition.');
              this.isLoading = false;
            });
        } else if(this.value === 'Manual Divide') {
            var isVal = true;
            this.template.querySelectorAll('lightning-input-field').forEach(element => {
                isVal = isVal && element.reportValidity();
            });
            if (isVal) {
                this.template.querySelectorAll('lightning-record-edit-form').forEach(element => {
                    element.submit();
                });
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Vouchers successfully created',
                        variant: 'success',
                    }),
                );
                this.closeQuickAction();
            } else {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating record',
                        message: 'Please enter all the required fields',
                        variant: 'error',
                    }),
                );
            }
        }
    }

    showToastMessage(variant, title, message) {
        const toastEvent = new ShowToastEvent({
          variant: variant,
          title: title,
          message: message,
        });
        this.dispatchEvent(toastEvent);
    }

    closeQuickAction() {
        const closeQA = new CustomEvent('close');
        // Dispatches the event.
        this.dispatchEvent(closeQA);
    }
}