import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import BOOKING_OBJECT from '@salesforce/schema/Booking__c';
import SERVICE_TYPE from '@salesforce/schema/Booking__c.Service_Type__c';

export default class MultipleSelectServiceTypeParent extends LightningElement {
    @track selectedValue;
    @track selectedValueList = [];
    @api objectApiName;
    @api options;
    @track error;

    @wire(getObjectInfo, { objectApiName: BOOKING_OBJECT })
    bookingInfo;

    @wire(getPicklistValues, {recordTypeId: '$bookingInfo.data.defaultRecordTypeId', fieldApiName: SERVICE_TYPE})
    dataResponse({ error, data }) {
        if (data) {
            let optionServiceType = [{
                label: 'All',
                value: 'All'
            }];
            for(var key in data.values) {
                console.log(JSON.stringify(data.values[key].value));
                optionServiceType.push({ 
                    label:  data.values[key].value,
                    value:  data.values[key].value
                });
            }
            this.options = optionServiceType;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.record = undefined;
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

    //for single select picklist
    handleSelectOption(event){
        console.log(event.detail);
        this.selectedValue = event.detail;
        this.dispatchEvent(ev);
    }
 
    //for multiselect picklist
    handleSelectOptionList(event){
        console.log(event.detail);
        console.log(JSON.stringify(event.detail));
        this.selectedValueList = event.detail;
        let ev = new CustomEvent('selectoption', {detail:this.selectedValueList});
        this.dispatchEvent(ev);
    }
}