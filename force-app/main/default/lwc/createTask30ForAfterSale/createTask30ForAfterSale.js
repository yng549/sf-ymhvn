import { LightningElement, track , api} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import init from '@salesforce/apex/CreateTask30DaysForAfterSale.init';
import createTask30DaysForAfterSale from '@salesforce/apex/CreateTask30DaysForAfterSale.createTask30DaysForAfterSale';

export default class ChildLWC extends LightningElement {
    @api recordId;
    isShowSpinner = false;
    disabledButton = true;
    dateValue;
    errorMsg;
    isData = false;
    @track lstTask = [];
    connectedCallback() {
        this.doinit();
        var someDate = new Date(new Date().getTime()+(90*24*60*60*1000)); //added 90 days to todays date
        this.dateValue = someDate.toISOString();
    }
    doinit() {
        init({
            recordId : this.recordId
        }).then(apiResponse => {
            this.isShowSpinner = false;
            if(apiResponse.success) {
                this.lstTask = apiResponse.result;
                this.isData = this.lstTask.length > 0 ? true : false;
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
    }

    changeValue() {
        this.disabledButton = true;
        const dateRange = this.template.querySelector('lightning-input[data-id="comment"]');
        if(dateRange) {
            this.disabledButton = false;
        }
    }

    handleCreateTask() {
        const dateRange = this.template.querySelector('lightning-input[data-id="comment"]');
        console.log(dateRange.value);

        this.isShowSpinner = true;
        setTimeout(() => {
            createTask30DaysForAfterSale({
                strComment: dateRange.value,
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