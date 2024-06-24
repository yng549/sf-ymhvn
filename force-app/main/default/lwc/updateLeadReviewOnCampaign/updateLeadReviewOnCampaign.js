import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateLead from '@salesforce/apex/UpdateLeadReviewOnCampaign.updateLead';

export default class UpdateLeadReviewOnCampaign extends LightningElement {
    @api recordId;
    isShowSpinner = false;
    errorMsg = '';

    closeQuickAction() {
        const closeQA = new CustomEvent('close');
        // Dispatches the event.
        this.dispatchEvent(closeQA);
    }

    doneTypingInterval = 1000;
    typingTimer;
    updateLead() {
        this.isShowSpinner = true;
        clearTimeout(this.typingTimer);
        this.typingTimer = setTimeout(() => {
            updateLead({
                recordId: this.recordId
            }).then(apiResponse => {
                if(apiResponse.success) {
                    this.showToastMessage('Update successfully!', 'Success');
                } else {
                    this.showToastMessage(apiResponse.error, 'Error');
                }
            })
            .catch(error => {
                if(error) {
                    if (Array.isArray(error.body)) {
                        this.errorMsg = error.body.map(e => e.message).join(', ');
                    } else if (typeof error.body.message === 'string') {
                        this.errorMsg = error.body.message;
                    }
                }
            }).finally(() => {
                this.isShowSpinner = false;
            });
            
        }, this.doneTypingInterval);
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