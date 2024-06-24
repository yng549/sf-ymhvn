import { LightningElement, track , api} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createCase from '@salesforce/apex/createTaskForCaseImplementtation.createCase';

export default class ChildLWC extends LightningElement {
  
  @track displayMessage = '';
  @track isLoading;
  @track selectOption = [{
    label: 'Case Status Implementation',
    value: 'Case Status Implementation'
  }];
  @track _helpMessage;
  @api strSubject;
  @api strEstimateTime;
  @api recordId;

  handleInputChange(event) {
    console.log('aaa');
    this.strSubject = event.target.value;
  }
  changeEstimate(event) {
    console.log('bbbb');
    this.strEstimateTime = event.target.value;

  }

  closeQuickAction() {
    const closeQA = new CustomEvent('close');
    // Dispatches the event.
    this.dispatchEvent(closeQA);
    }

  handleSave() {
    if (!this.isLoading) {
      this.isLoading = true;
      this._helpMessage = '';
        createCase({
            strFullName: this.strSubject,
            dtEstimate: this.strEstimateTime,
            strCaseId: this.recordId
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
              this.showToastMessage('error', '', 'Failed to save rule.');
            }
          }
          this.isLoading = false;
        }).catch(e => {
          this.showToastMessage('error', '', 'Failed to save rule.');
          this.isLoading = false;
        });
      } else {
        this.isLoading = false;
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
}