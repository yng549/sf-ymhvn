import { LightningElement, track, api } from "lwc";
import search from "@salesforce/apex/EmailClass.search";
import getOpportunity from "@salesforce/apex/EmailClass.getOpportunity";
export default class EmailInput extends LightningElement {
    @track items = [];
    searchTerm = "";
    blurTimeout;
    @api recordoppty;
    isData = false;
    boxClass = "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus";

    @track _selectedValues = [];

       
    error;

    showToastMessage(msg, type) {
        this.dispatchEvent(
            new ShowToastEvent({
                variant: type,
                message: msg
            })
        );
    }

    selectedValuesMap = new Map();

    connectedCallback() {
        this.getOpportunityInit();
    }

    getOpportunityInit() {
        getOpportunity({
            recordId: this.recordoppty
        }).then(apiResponse => {
                if(apiResponse.success) {
                    this._selectedValues.push("huythe3@gmail.com");
                    if(this._selectedValues.length) {
                        this.isData = true;
                    }
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
        });
    }
    
    get selectedValues() {
        return this._selectedValues;
    }
    set selectedValues(value) {
        this._selectedValues = value;

        const selectedValuesEvent = new CustomEvent("selection", { detail: { selectedValues: this._selectedValues} });
        this.dispatchEvent(selectedValuesEvent);
    }

    handleInputChange(event) {
        event.preventDefault();
        if (event.target.value.length < 3) {
            return;
        }

        search({ searchString: event.target.value })
            .then((result) => {
                this.items = result;
                if (this.items.length > 0) {
                    this.boxClass =
                        "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus slds-is-open";
                }
            })
            .catch((error) => {
                console.error("Error:", error);
            });
    }

    handleBlur() {
        console.log("In onBlur");
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.blurTimeout = setTimeout(() => {
            this.boxClass = "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus";
            const value = this.template.querySelector('input.input').value
            if (value !== undefined && value != null && value !== "") {
                this.selectedValuesMap.set(value, value);
                this.selectedValues = [...this.selectedValuesMap.keys()];
            }

            this.template.querySelector('input.input').value = "";
        }, 300);
    }

    get hasItems() {
        return this.items.length;
    }

    handleKeyPress(event) {
        if (event.keyCode === 13) {
            event.preventDefault(); // Ensure it is only this code that runs

            const value = this.template.querySelector('input.input').value;
            if (value !== undefined && value != null && value !== "") {
                this.selectedValuesMap.set(value, value);
                this.selectedValues = [...this.selectedValuesMap.keys()];
            }
            this.template.querySelector('input.input').value = "";
        }
    }

    handleRemove(event) {
        const item = event.target.label;
        this.selectedValuesMap.delete(item);
        this.selectedValues = [...this.selectedValuesMap.keys()];
    }

    onSelect(event) {
        this.template.querySelector('input.input').value = "";
        let ele = event.currentTarget;
        let selectedId = ele.dataset.id;
        let selectedValue = this.items.find((record) => record.Id === selectedId);
        this.selectedValuesMap.set(selectedValue.Email, selectedValue.Name);
        this.selectedValues = [...this.selectedValuesMap.keys()];

        //As a best practise sending selected value to parent and inreturn parent sends the value to @api valueId
        let key = this.uniqueKey;
        const valueSelectedEvent = new CustomEvent("valueselect", {
            detail: { selectedId, key }
        });
        this.dispatchEvent(valueSelectedEvent);

        if (this.blurTimeout) {
            clearTimeout(this.blurTimeout);
        }
        this.boxClass = "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus";
    }

    @api reset() {
        this.selectedValuesMap = new Map();
        this.selectedValues = [];
    }

    @api validate() {
        this.template.querySelector('input').reportValidity();
        const isValid = this.template.querySelector('input').checkValidity();
        return isValid;
    }
}