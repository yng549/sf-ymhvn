import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOrderLineItem from '@salesforce/apex/applyOrderLineItem.getOrderLineItem';
import saveCreateObjcet from '@salesforce/apex/applyOrderLineItem.saveCreateObjcet';
import getProductChildren from '@salesforce/apex/applyOrderLineItem.getProductChildren';
import {refreshApex} from '@salesforce/apex';

export default class SubmitUseToProductServicePackage extends LightningElement {
    @api recordId;
    @track productList;
    @track productSessionList;
    @track disabledButton = false;
    @track isShowSpinner = false;
    @track flagHasProduct = false;
    @track bShowModal = false;
    @track lstOrderDetails = [];
    @track flagBeforeSave = false;
    
    closeQuickAction() {
        const closeQA = new CustomEvent('close');
        // Dispatches the event.
        this.dispatchEvent(closeQA);
    }

    connectedCallback() {
        this.getDataInit();
    }


    closeModal() {
        this.bShowModal = false;
        this.lstOrderDetails = [];
        this.flagBeforeSave = false;
    }
   

    getDataInit() {
        let rowindex = 1;
        const listMember = [];
        
        getOrderLineItem({
            strOrderId : this.recordId  
        }).then(apiResponse => {
            if(apiResponse.success) {
                const result = apiResponse.result;
                result.forEach(element => {
                    let lstChild = [];
                    element.lstOrderLineDetail.forEach(e => {
                        var objChild = {
                            'Id': e.Id
                            , 'Name': e.Name
                            , 'Order_Line_Item': e.Order_Line_Item
                            , 'Product_Detail_Service': e.Product_Detail_Service
                            , 'Product_Name': e.Product_Name
                            , 'Quantity_on_Product': e.Quantity_on_Product
                            , 'Remain': e.Remain
                            , 'selected': false
                        };
                        lstChild.push(objChild);
                    });
                    let member = { 
                        'Id': element.Id,
                        'ProductId': element.ProductId,
                        'ProductName' : element.ProductName,
                        'List_Price': element.List_Price,
                        'Unit_Price': element.Unit_Price,
                        'Quantity': element.Quantity,
                        'Total_Price': element.Total_Price,
                        'hideBool': element.hideBool,
                        'lstOrderLineDetail': lstChild,
                        'URLProduct': window.location.origin + '/' + element.ProductId,
                        'selected' : false,
                        'OrderBy': rowindex ++
                    };
                    listMember.push(member);
                });
                this.productList = listMember;
                if(this.productList.length > 0) {
                    this.flagHasProduct = true;
                }
                console.log(this.productList);
            } else {
                this.showToastMessage(apiResponse.error, 'Error');
            }
        }).catch((error) => {
            if (error && error.body) {
                this.showToastMessage(error.body.message, 'error');
            }
            else if (error){
                this.showToastMessage(error.message, 'error');
            }
        })
    }

    hideAndShow(event) {
        let indx = event.target.dataset.recordId;
        if (this.productList) {
            let recs = JSON.parse(JSON.stringify(this.productList));
            recs[indx].hideBool = !recs[indx].hideBool;
            this.productList = recs;
            console.log('After Change ' + this.productList[indx].hideBool);
        }
        if (event.target.label === "-") {
            event.target.label = "+";
        } else {
            event.target.label = "-";
        }
    }

    //Select Group
    handleSelectGroup(event) {
        this.disabledButton = false;
        const strIdGroup = event.target.value;
        if (event.target.checked) {
            this.setCheckGroup(true, strIdGroup);
        }
        if (!event.target.checked) {
            this.setCheckGroup(false, strIdGroup);
        }

        for (var i = 0; i < this.productList.length; i++) {
            for (var n = 0; n < this.productList[i].lstOrderLineDetail.length; n++) {
                if(this.productList[i].lstOrderLineDetail[n].selected) {
                    this.disabledButton = true;
                    break;
                }
            }
        }
    }

    //Check từng group
    setCheckGroup(flag, strIdGroup) {
        for (var i = 0; i < this.productList.length; i++) {
            if (this.productList[i].Id === strIdGroup) {
                this.productList[i].selected = flag;
                for (var n = 0; n < this.productList[i].lstOrderLineDetail.length; n++) {
                    this.productList[i].lstOrderLineDetail[n].selected = flag;
                }   
            }
        }
    }

    selectedProduct(event){
        const strIdGroup = event.target.value;
        for (var i = 0; i < this.productList.length; i++) {
            if (this.productList[i].Id === strIdGroup) {
                for (var n = 0; n < this.productList[i].lstOrderLineDetail.length; n++) {
                    if(this.productList[i].lstOrderLineDetail[n].Id === event.target.name) {
                        if (event.target.checked) {
                            this.productList[i].lstOrderLineDetail[n].selected = true;
                        }
                        if (!event.target.checked) {
                            this.productList[i].lstOrderLineDetail[n].selected = false;
                        }
                    }
                }   
            }
        }
        for (var i = 0; i < this.productList.length; i++) {
            if (this.productList[i].Id === strIdGroup) {
                this.productList[i].selected = true;
                for (var n = 0; n < this.productList[i].lstOrderLineDetail.length; n++) {
                    if(!this.productList[i].lstOrderLineDetail[n].selected) {
                        this.productList[i].selected = false;
                        break;
                    }
                }
            }
        }

        this.disableAndEnableButton();
    }


    disableAndEnableButton() {
        let selectedRows = this.template.querySelectorAll('lightning-input');
        this.disabledButton = false;
        // based on selected row getting values of the contact
        for(let i = 0; i < selectedRows.length; i++) {
             if(selectedRows[i].type === 'checkbox') {
                if(selectedRows[i].checked) {
                    this.disabledButton = true;
                    break;
                }
            }
        }
    }

    confirmBeforeSave() {
        let listInser = [];
        this.isShowSpinner = true;
        for (var i = 0; i < this.productList.length; i++) {
            for (var n = 0; n < this.productList[i].lstOrderLineDetail.length; n++) {
                if(this.productList[i].lstOrderLineDetail[n].selected) {
                    listInser.push(this.productList[i].lstOrderLineDetail[n]);
                }
            }
        }
        setTimeout(() => {
            getProductChildren({
                recordIdOrder : this.recordId,
                lstOrderDetailsDTO : listInser
            }).then(apiResponse => {
                this.isShowSpinner = false;
                if(apiResponse.success) {
                    this.lstOrderDetails = apiResponse.result;
                } else {
                    this.showToastMessage(apiResponse.error, 'Error');
                }
            }).catch((error) => {
                this.isShowSpinner = false;
                if (error && error.body) {
                    this.showToastMessage(error.body.message, 'error');
                }
                else if (error){
                    this.isShowSpinner = false;
                    this.showToastMessage(error.message, 'error');
                }
            })
            }, 200);
            this.bShowModal = true;
    }

    checkConfirm(event) {
        if(event.target.checked) {
            this.flagBeforeSave = true;
        } else {
            this.flagBeforeSave = false;
        }
    }

    saveRecord() {
        this.flagBeforeSave = false;
        this.isShowSpinner = true;
        let listInser = [];
        for (var i = 0; i < this.productList.length; i++) {
            for (var n = 0; n < this.productList[i].lstOrderLineDetail.length; n++) {
                if(this.productList[i].lstOrderLineDetail[n].selected) {
                    listInser.push(this.productList[i].lstOrderLineDetail[n]);
                }
            }
        }

        setTimeout(() => {
            
            saveCreateObjcet({
                recordIdOrder : this.recordId,
                lstOrderDetailsDTO : listInser
            }).then(apiResponse => {
                if(apiResponse.success) {
                    this.isShowSpinner = false;
                    this.flagBeforeSave = true;
                    this.showToastMessage('Save successfully!', 'success');
                    this.closeQuickAction();
                    location.reload();
                } else {
                    this.isShowSpinner = false;
                    this.flagBeforeSave = true;
                    this.showToastMessage(apiResponse.error, 'Error');
                }
            }).catch((error) => {
                this.isShowSpinner = false;
                this.flagBeforeSave = true;
                if (error && error.body) {
                    this.showToastMessage(error.body.message, 'error');
                }
                else if (error){
                    
                    this.showToastMessage(error.message, 'error');
                }
            })
            }, 200);
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