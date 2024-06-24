import { LightningElement, track , api} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createTaskPCAForOppty from '@salesforce/apex/CreateTaskForPCAOptyController.createTaskPCAForOppty';

export default class CreateTaskForPCAOpty extends LightningElement {
    @api recordId;
    isShowSpinner = false;
    disabledButton = true;
    
    changeValue() {
        this.disabledButton = true;
        const dateRange = this.template.querySelector('lightning-input[data-id="numberRange"]');
        if(dateRange.value > 0) {
            this.disabledButton = false;
        }
    }

    handleCreateTask() {
        const dateRange = this.template.querySelector('lightning-input[data-id="numberRange"]');
        console.log(dateRange.value);

        this.isShowSpinner = true;
        setTimeout(() => {
            createTaskPCAForOppty({
                strInputRange: dateRange.value,
                strRecordId : this.recordId,
                strNameObject: 'Opportunity'
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
            }, 50);
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