import { LightningElement, wire, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getQuoteByRecordId from '@salesforce/apex/EdtQuoteController.getQuoteByRecordId';
import getPickListValuesIntoList  from '@salesforce/apex/EdtQuoteController.getPickListValuesIntoList';
import updateQuote from '@salesforce/apex/EdtQuoteController.updateQuote';
export default class EditQuote extends LightningElement {
    @api recordId;
    @api quoteSelelect;
    @track errorMsg = '';
    @track lstQuoteReturn = [];
    currentAccount = ''; 
    @track listValues = [{}];
    isShowSpinner = false;
    flagNotifyText = false;
    isData = false;
    @track flagDeliveryDate = false;

    updateQuote() {
        this.isShowSpinner = true;
        console.log(this.quoteSelelect);
        setTimeout(() => {
            updateQuote({
                json : JSON.stringify(this.quoteSelelect)
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
            }, 50);
    }
    


    getPicklist() {
        this.quoteSelelect = '';
        getPickListValuesIntoList().then(apiResponse => {
                if(apiResponse.success) {
                    let options = [];
                    for(var key in apiResponse.result){
                        let option = {
                            label: apiResponse.result[key],
                            value: apiResponse.result[key]
                        };
                        options.push(option);
                    }
                    this.listValues = options
                    console.log(JSON.stringify(this.listValues));
                } else {
                    this.showToastMessage(apiResponse.error, 'Error');
                }
            })
            .catch(error => {
                this.quoteSelelect = '';
                if(error) {
                    if (Array.isArray(error.body)) {
                        this.errorMsg = error.body.map(e => e.message).join(', ');
                    } else if (typeof error.body.message === 'string') {
                        this.errorMsg = error.body.message;
                    }
                }
        })
    }

    // now get the industry picklist values

    connectedCallback() {
        this.getPicklist();
        this.getQuoteInit();
        
    }

    getQuoteInit() {
        this.quoteSelelect = '';
        getQuoteByRecordId({
                recordId : this.recordId,
            }).then(apiResponse => {
                if(apiResponse.success) {
                    const data = apiResponse.result;
                    this.lstQuoteReturn.push(data);
                    for(var i=0; i < this.lstQuoteReturn.length; i++) {
                        this.quoteSelelect = this.lstQuoteReturn[i];                                                                                                                  
                    }
                    console.log(this.quoteSelelect);
                    this.listValues.forEach(e => {
                        if(e.value === this.quoteSelelect.ProductBikeType) {
                            this.currentAccount = e.value;
                        }
                    });
                    this.isData = true;
                    if(this.quoteSelelect.DeliveryDate) {
                        this.flagDeliveryDate = true;
                    }
                    console.log(this.currentAccount);
                } else {
                    this.showToastMessage(apiResponse.error, 'Error');
                }
            })
            .catch(error => {
                this.quoteSelelect = '';
                if(error) {
                    if (Array.isArray(error.body)) {
                        this.errorMsg = error.body.map(e => e.message).join(', ');
                    } else if (typeof error.body.message === 'string') {
                        this.errorMsg = error.body.message;
                    }
                }
        })
    }


    handleChange(event){
        if(event.target.dataset.id === 'FirstAccountName'){
            this.quoteSelelect.FirstAccountName = event.target.value;
        } else if(event.target.dataset.id === 'LastAccountName') {
            this.quoteSelelect.LastAccountName = event.target.value;
        } else if(event.target.dataset.id === 'AddressFull') {
            this.quoteSelelect.AddressFull = event.target.value;
        } else if(event.target.dataset.id === 'IDNo') {
            this.quoteSelelect.IDNo = event.target.value;
        } else if(event.target.dataset.id === 'TaxCode') {
            this.quoteSelelect.TaxCode = event.target.value;
        } else if(event.target.dataset.id === 'PersonMobilePhone') {
            this.quoteSelelect.PersonMobilePhone = event.target.value;
        } else if(event.target.dataset.id === 'Email') {
            this.quoteSelelect.Email = event.target.value;
        } else if(event.target.dataset.id === 'ModelName') {
            this.quoteSelelect.ModelBikeName = event.target.value;
        } else if(event.target.dataset.id === 'ColorName') {
            this.quoteSelelect.ProductColorName = event.target.value;
        } else if(event.target.dataset.id === 'CapacityName') {
            this.quoteSelelect.Capacity = event.target.value;
        } else if(event.target.dataset.id === 'OriginName') {
            this.quoteSelelect.ProductOrigin = event.target.value;
        } else if(event.target.dataset.id === 'ProductType2') {
            this.quoteSelelect.ProductBikeType = event.target.value;
        } else if(event.target.dataset.id === 'EstimateDate') {
            this.quoteSelelect.DeliveryDate = event.target.value;
            if(this.quoteSelelect.DeliveryDate) {
                this.flagDeliveryDate = true;
            } else {
                this.flagDeliveryDate = false;
            }
        } else if(event.target.dataset.id === 'Payment1') {
            this.quoteSelelect.Payment1 = event.target.value;
        } else if(event.target.dataset.id === 'Payment2') {
            this.quoteSelelect.Payment2 = event.target.value;
        } else if(event.target.dataset.id === 'Payment3') {
            this.quoteSelelect.Payment3 = event.target.value;
        } else if(event.target.dataset.id === 'Discount') {
            // this.quoteSelelect.DiscountPercent = event.target.value ? event.target.value : 0;
            // if(this.quoteSelelect.DiscountPercent && this.quoteSelelect.DiscountPercent > 0) {
            //     parseFloat(this.quoteSelelect.DiscountPercent).toFixed(2)
            //     this.quoteSelelect.SalePrice = this.quoteSelelect.ListPriceVAT - (this.quoteSelelect.ListPriceVAT*this.quoteSelelect.DiscountPercent)/100;
            // } else {
            //     this.quoteSelelect.SalePrice = this.quoteSelelect.ListPriceVAT;
            // }
            
            if(this.quoteSelelect.DiscountAmount) {
                this.flagNotifyText = true;
            }
            this.quoteSelelect.DiscountAmount = event.target.value ? event.target.value : 0;
            if(this.quoteSelelect.DiscountAmount && this.quoteSelelect.DiscountAmount > 0) {
                this.quoteSelelect.SalePrice = this.quoteSelelect.ListPriceVAT - this.quoteSelelect.DiscountAmount;
            } else {
                this.quoteSelelect.SalePrice = this.quoteSelelect.ListPriceVAT;
            }
            
            if(this.quoteSelelect.DiscountAmount) {
                this.flagNotifyText = true;
            }
            
        } else if(event.target.dataset.id === 'ECommerceOrder') {
            this.quoteSelelect.ECommerceOrder = event.target.checked;
        } else if(event.target.dataset.id === 'PriceTradeInBike') {
            this.quoteSelelect.PriceTradeInBike = event.target.value;
        } else if(event.target.dataset.id === 'Finance') {
            this.quoteSelelect.Finance = event.target.value;
        } else if(event.target.dataset.id === 'VoucherAmount') {
            this.quoteSelelect.VoucherAmount = event.target.value;
        } else if(event.target.name === 'PromotionPack') {
            for(var i = 0; i < this.quoteSelelect.lstPromotion.length; i++) {
                if(this.quoteSelelect.lstPromotion[i].Id === event.target.dataset.id) {
                    this.quoteSelelect.lstPromotion[i].isChecked = event.target.checked;
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