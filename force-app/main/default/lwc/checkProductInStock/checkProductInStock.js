import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import searchProductCheckStock from '@salesforce/apex/ChangeProductWithQuoteLIneItem.searchProductCheckStock';

export default class CheckProductInStock extends LightningElement {
    lst;
    errorMsg = '';
    isData = false;
    @track allFilteredClients;
    doneTypingInterval = 800;
    typingTimer;

    handleFilter() {
        this.isShowSpinner = true;
        clearTimeout(this.typingTimer);
        this.typingTimer = setTimeout(() => {
            let inputValue = this.template.querySelector("[data-name='searchProd']");
            this.allFilteredClients = [];   
            searchProductCheckStock({
                strKeySearch : inputValue.value
            }).then(apiResponse => {
                if(apiResponse.success) {
                    this.isShowSpinner = false;
                    this.allFilteredClients = apiResponse.result;
                    console.log(this.allFilteredClients);
                    
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
        }, this.doneTypingInterval);
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