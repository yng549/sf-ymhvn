import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getQuotelineItem from '@salesforce/apex/ChangeProductWithQuoteLIneItem.getQuotelineItem';
import getWarehouseInventoryByDODL from '@salesforce/apex/ChangeProductWithQuoteLIneItem.getWarehouseInventoryByDODL';
import updateQuoteLineItem from '@salesforce/apex/ChangeProductWithQuoteLIneItem.updateQuoteLineItem';

export default class ChangeProductWithQuoteLineItem extends LightningElement {
    objQuoteLineItem;
    errorMsg = '';
    isData = false;
    @api recordId;
    @track lstProductWarehous = [];
    strModelName;
    flagDisabledButtonSave = false;
    isShowSpinner = false;
    connectedCallback() {
        this.init();
    }

    objProductSelected;

    init() {
        this.objQuoteLineItem = '';
        this.asyncGetQuotelineItem()
            .then((result) => {
                getWarehouseInventoryByDODL({
                    recordQuoteId : this.recordId
                }).then(apiResponse => {
                        if(apiResponse.success) {
                            this.lstProductWarehous = apiResponse.result;
                            this.lstProductWarehous.forEach(element => {
                                element.URLWareHouse = window.location.origin + '/' + element.Product2Id;
                                if(element.QoH > 0) {
                                    element.availableInStock = true;
                                }
                            });
                            console.log(this.lstProductWarehous);
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
                })
        });
    }

    

    checkBox(event) {
        this.flagDisabledButtonSave = false;
        this.objProductSelected = '';
        const boxes = this.template.querySelectorAll('lightning-input');
        boxes.forEach(box => box.checked = event.target.name === box.name);

        for(let key in this.lstProductWarehous) {
            if(event.target.dataset.id == this.lstProductWarehous[key].Product2Id) {
                this.lstProductWarehous[key].isChecked = event.target.checked;
                this.objProductSelected = this.lstProductWarehous[key];
            } else {
                if(this.lstProductWarehous[key].isChecked) {
                    this.lstProductWarehous[key].isChecked = false;
                }
            }
        }
        
        
        if(this.objProductSelected) {
            this.flagDisabledButtonSave = true;
        }
        console.log(this.objProductSelected);
    }

    @track allFilteredClients;
    clientFilterQuery;
    lstSearchByCondition;
    handleFilter(event) {
        this.allFilteredClients=this.lstProductWarehous;
        this.clientFilterQuery= event.target.value;
        var __FOUND = this.allFilteredClients.filter((cli, index)=> {
            if(cli.ProductCode.toUpperCase().includes(this.clientFilterQuery.toUpperCase())
                || cli.ColorType.toUpperCase().includes(this.clientFilterQuery.toUpperCase())
                || cli.ProductNameVN.toUpperCase().includes(this.clientFilterQuery.toUpperCase())
                || cli.Price <= this.clientFilterQuery) {
                return true;
            }
        });
        if(__FOUND == undefined || __FOUND==[])
            this.allFilteredClients=this.lstProductWarehous;
        else
            this.allFilteredClients=__FOUND;
        //this.handlePagination();//filtering the client list based on user input
    }

    handleSubmit() {
        this.isShowSpinner = true;
        setTimeout(() => {
            updateQuoteLineItem({
                objWarehouseInventoryProductDTO: this.objProductSelected,
                recordQuoteId : this.recordId
            }).then(apiResponse => {
                if(apiResponse.success) {
                    this.isShowSpinner = false;
                    this.showToastMessage('Save successfully!', 'success');
                    this.closeQuickAction();
                    location.reload();
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
            }, 500);
        
    }

    async asyncGetQuotelineItem() {
        getQuotelineItem({
                recordQuoteId : this.recordId
            }).then(apiResponse => {
                if(apiResponse.success) {
                    this.isData = true;
                    this.objQuoteLineItem = apiResponse.result;
                    console.log(JSON.stringify(this.objQuoteLineItem));
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
        })
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