import {LightningElement, wire, api, track} from 'lwc';
import getContactsByStatus from '@salesforce/apex/UpdateOwnerLeadSaleSupForSaleSenior.getContactsByStatus';
import updateOwnerLead from '@salesforce/apex/UpdateOwnerLeadSaleSupForSaleSenior.updateOwnerLead';
import { NavigationMixin } from 'lightning/navigation';  
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
const columns = [
                  { label: 'Name', fieldName: 'Name', sortable: "true"},
                  { label: 'CreatedDate', fieldName: 'CreatedDate', type: 'date', sortable: "true"},
                  { label: 'LeadSource', fieldName: 'LeadSource', sortable: "true"},
                    {type: "button", typeAttributes: { label: 'Edit',  
                                                    name: 'Edit',  
                                                    title: 'Edit',  
                                                    disabled: false,    
                                                    value: 'edit',  
                                                    iconPosition: 'left'}}
                ];
const DELAY = 30000;
export default class TabUpdateOwnerLeadSaleSupForSaleSenior extends NavigationMixin(LightningElement) {  

    @api objectName = 'Lead';
    @api fieldName = 'Status';
    @track fieldLabel;
    @api recordTypeId;
    @api value = 'New';
    @track options;
    apiFieldName;

    @wire(getObjectInfo, { objectApiName: '$objectName' })
    getObjectData({ error, data }) {
        if (data) {
            if (this.recordTypeId == null)
                this.recordTypeId = data.defaultRecordTypeId;
            this.apiFieldName = this.objectName + '.' + this.fieldName;
            this.fieldLabel = data.fields[this.fieldName].label;
            
        } else if (error) {
            // Handle error
            console.log('==============Error  ');
            console.log(error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: '$apiFieldName' })
    getPicklistValues({ error, data }) {
        if (data) {
            // Map picklist values
            this.options = data.values.map(plValue => {
                return {
                    label: plValue.label,
                    value: plValue.value
                };
            });

        } else if (error) {
            // Handle error
            console.log('==============Error  ' + error);
            console.log(error);
        }
    }
    
    delayTimeout;
    handleChange(event) {
        this.handleIsLoading(true);
        window.clearTimeout(this.delayTimeout);
        this.value = event.detail.value;
        this.delayTimeout = setTimeout(() => {
            getContactsByStatus({
                strStatus: this.value
            }).then(apiResponse => {
                if(apiResponse.success) {
                    this.showToastMessage('Search successfully!', 'success');
                    this.data = result.data;
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
            }).finally(()=>{
                this.handleIsLoading(false);
            });
        }, DELAY);
    }

    @track data = [];
    @track columns = columns;
    @track sortBy;
    @track sortDirection;
    isModalOpen = false;
    @track isLoading = false;
    @track strIdLead = '';
    errorMsg = '';

    @wire(getContactsByStatus, { strStatus: '$value' })
    contacts(result) {
        if (result.data) {
            this.data = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.data = undefined;
        }
    }

    doSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }

    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.data));
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1: -1;
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        this.data = parseData;
    }    

    callRowAction( event ) {
        const recId =  event.detail.row.Id;
        const actionName = event.detail.action.name;  
        if ( actionName === 'Edit' ) {  
            this.isModalOpen = true;
            this.strIdLead = recId;
        }
    } 

    submitDetails() {
        let dataRefresh = [];
        this.handleIsLoading(true);
        setTimeout(() => {
            updateOwnerLead({
                strLeadId: this.strIdLead
            }).then(apiResponse => {
                if(apiResponse.success) {
                    this.showToastMessage('Save successfully!', 'success');
                    // this[NavigationMixin.Navigate]({  
                    //     type: 'standard__recordPage',  
                    //     attributes: {  
                    //         recordId: this.strIdLead,  
                    //         objectApiName: 'Lead',  
                    //         actionName: 'view'  
                    //     }  
                    // });
                    for(var i=0; i < this.data.length;i++) {
                        if(this.data[i].Id != this.strIdLead) {
                            dataRefresh.push(this.data[i]);
                        }
                    }
                    this.data = dataRefresh;
                    this.closeQuickAction();
                    var url = window.location.origin + '/' + this.strIdLead;
                    window.open(url, "_blank");  
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
            }).finally(()=>{
                this.handleIsLoading(false);
            });
        }, 5000);

        
    }

    handleIsLoading(isLoading) {
        this.isLoading = isLoading;
    }

    showToastMessage(msg, type) {
        this.dispatchEvent(
            new ShowToastEvent({
                variant: type,
                message: msg
            })
        );
    }

    closeQuickAction() {
        this.isModalOpen = false;
        this.strIdLead = '';
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}