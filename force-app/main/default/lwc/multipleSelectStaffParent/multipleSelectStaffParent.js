import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getLstContactByRecordType from '@salesforce/apex/CalendarBookingController.getLstContactByRecordType';

export default class MultipleSelectStaffParent extends LightningElement {
    @track selectedValue;
    @track selectedValueList = [];
    @api options;
    @api objectApiName;


    connectedCallback() {
        setTimeout(() => {
            let optionDODL = [{
                label: 'All',
                value: 'All'
            }];
            getLstContactByRecordType().then(apiResponse => {
                if(apiResponse.success) {
                    const data = apiResponse.result;
                    for (var key in data) {
                        // Here key will have index of list of records starting from 0,1,2,....                
                        optionDODL.push({ label:  data[key].Name,
                                         value:  data[key].Id});
                    }
                }
                this.options = optionDODL;
            }).catch((error) => {
                if (error && error.body) {
                    this.showToastMessage(error.body.message, 'error');
                }
                else if (error){
                    this.showToastMessage(error.message, 'error');
                }
            })
            
        }, 500);
    }
     
    showToastMessage(msg, type) {
        this.dispatchEvent(
            new ShowToastEvent({
                variant: type,
                message: msg
            })
        );
    }

    //for single select picklist
    handleSelectOption(event){
        console.log(event.detail);
        this.selectedValue = event.detail;
        this.dispatchEvent(ev);
    }
 
    //for multiselect picklist
    handleSelectOptionList(event){
        console.log(event.detail);
        this.selectedValueList = event.detail;
        let ev = new CustomEvent('selectoption', {detail:this.selectedValueList});
        this.dispatchEvent(ev);
    }
}