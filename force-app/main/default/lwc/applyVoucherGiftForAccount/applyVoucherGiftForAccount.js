import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import searchVoucherByKeyInput from '@salesforce/apex/VoucherGiftForAccount.searchVoucherByKeyInput';
import updateVoucherRedeem from '@salesforce/apex/VoucherGiftForAccount.updateVoucherRedeem';

export default class ApplyVoucherGiftForAccount extends LightningElement {
    isShowSpinner = false;
    @track errorMsg = '';
    @api recordId;
    isData = false;
    disabledButton = false;
    @track items = []; //this holds the array for records with value & label
   


    @track vocherSearch;
    handleFilter() {
        this.vocherSearch = '';
        let data = [];
       
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
                        e.hideBool = false;
                        e.lstProductCampaignDTO.forEach(i => {
                            i.UrlProductCampaign = window.location.origin + '/' + i.Id;
                        });
                    });
                    this.vocherSearch = data[0];
                    this.isData = true;
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

    closeQuickAction() {
        const closeQA = new CustomEvent('close');
        // Dispatches the event.
        this.dispatchEvent(closeQA);
    }

    setBoxes(event) {
        var flag = false;
        for(let j = 0; j < this.vocherSearch.lstProductCampaignDTO.length; j++) {
            if(flag) {
                return;
            }
            if(this.vocherSearch.lstProductCampaignDTO[j].Id == event.target.dataset.id) {
                this.vocherSearch.lstProductCampaignDTO[j].IsChecked = event.target.checked;
                flag = true;
            }
        }
        
        
    }

    setBoxGiftGroup(event){
        this.disabledButtonStep1 = true;
        const element = this.template.querySelector("[data-name='consent']");
        const theDiv = this.template.querySelectorAll('lightning-input[data-name="' +event.target.dataset.name+ '"]');
        console.log(element); // always null
        // based on selected row getting values of the contact
        var flag = false;
        for(let j = 0; j < this.vocherSearch.lstGiftGroupDTO.length; j++) {
            if(flag) {
                break;
            }
            if(this.vocherSearch.lstGiftGroupDTO[j].Id == event.target.dataset.id) {
                for(let k = 0; k < this.vocherSearch.lstGiftGroupDTO[j].lstProductGift.length; k++) {
                    if(this.vocherSearch.lstGiftGroupDTO[j].Type === '1 option') {
                        if(event.target.name == this.vocherSearch.lstGiftGroupDTO[j].lstProductGift[k].ProductId) {
                            this.vocherSearch.lstGiftGroupDTO[j].lstProductGift[k].IsChecked = event.target.checked;
                            flag = true;
                            if(event.target.checked) {
                                for(var i=0; i < theDiv.length; i++) {
                                    if(!theDiv[i].checked) {
                                        theDiv[i].disabled = true;
                                    }
                                }
                            } else if(!event.target.checked 
                                && this.vocherSearch.lstGiftGroupDTO[j].lstProductGift.filter(e => e.IsChecked).length < 1) {
                                for(var i=0; i < theDiv.length; i++) {
                                    if(theDiv[i].disabled) {
                                        theDiv[i].disabled = false;
                                    }
                                }
                            }
                            break;
                        }
                    } else if(this.vocherSearch.lstGiftGroupDTO[j].Type === '2 options') {
                        if(event.target.name == this.vocherSearch.lstGiftGroupDTO[j].lstProductGift[k].ProductId) {
                            this.vocherSearch.lstGiftGroupDTO[j].lstProductGift[k].IsChecked = event.target.checked;
                            flag = true;
                            if(event.target.checked 
                                && this.vocherSearch.lstGiftGroupDTO[j].lstProductGift.filter(e => e.IsChecked).length == 2) {
                                for(var i=0; i < theDiv.length; i++) {
                                    if(!theDiv[i].checked) {
                                        theDiv[i].disabled = true;
                                    }
                                }
                            } else if(!event.target.checked 
                                && this.vocherSearch.lstGiftGroupDTO[j].lstProductGift.filter(e => e.IsChecked).length < 2) {
                                for(var i=0; i < theDiv.length; i++) {
                                    if(theDiv[i].disabled) {
                                        theDiv[i].disabled = false;
                                    }
                                }
                            }
                            break;
                        }
                    } else if(this.vocherSearch.lstGiftGroupDTO[j].Type === 'All') {
                        if(event.target.name == this.vocherSearch.lstGiftGroupDTO[j].lstProductGift[k].ProductId) {
                            this.vocherSearch.lstGiftGroupDTO[j].lstProductGift[k].IsChecked = event.target.checked;
                            flag = true;
                            break;
                        }
                    }
                }
            }
        }
    }

    update() {
        this.isShowSpinner = true;
        setTimeout(() => {
            updateVoucherRedeem({
                objVoucherDTO: this.vocherSearch,
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