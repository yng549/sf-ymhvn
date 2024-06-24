import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import searchVoucherByKeyInput from '@salesforce/apex/voucherCashForOrder.searchVoucherByKeyInput';
import createPaymentForOrder from '@salesforce/apex/voucherCashForOrder.createPaymentForOrder';

export default class VoucherDiscountForOrder extends LightningElement {
    @api recordId;
    isData = false;
    isShowSpinner = false;
    disabledButton = true;
    dateValue;
    errorMsg;
    @api objVoucher;

    changeValue() {
        this.disabledButton = true;
        const dateRange = this.template.querySelector('lightning-input[data-id="imei"]');
        if(dateRange.value) {
            this.disabledButton = false;
        }
    }

    checkImei(){
        const dateRange = this.template.querySelector('lightning-input[data-id="imei"]');
        this.objVoucher = '';
        var lstVoucher = [];
        searchVoucherByKeyInput({
            strSearchKey: dateRange.value,
            recordId : this.recordId
        }).then(apiResponse => {
            if(apiResponse.success) {
                const data = apiResponse.result;
                lstVoucher.push(data);
                lstVoucher.forEach(e => {
                    e.UrlVoucher = window.location.origin + '/' + e.Id;
                    
                });
                console.log('lstVoucher',this.objVoucher);
                this.objVoucher = lstVoucher[0];
                this.isData = true;
            } else {
                this.showToastMessage(apiResponse.error, 'Error');
            }
        })
        .catch(error => {
            this.objVoucher = '';
            if(error) {
                if (Array.isArray(error.body)) {
                    this.errorMsg = error.body.map(e => e.message).join(', ');
                } else if (typeof error.body.message === 'string') {
                    this.errorMsg = error.body.message;
                }
            }
        })
    }

    createPayment() {
        this.isShowSpinner = true;
        setTimeout(() => {
            createPaymentForOrder({
                objVoucherDTO : this.objVoucher,
                recordId : this.recordId
            }).then(apiResponse => {
                this.isShowSpinner = false;
                if(apiResponse.success) {
                    this.showToastMessage('Save successfully!', 'success');
                    this.closeQuickAction();
                    this.dispatchEvent(new CustomEvent('recordChange'));
                    //location.reload();
                } else {
                    this.isShowSpinner = false;
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
            }, 250);
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