import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPickListValuesIntoList  from '@salesforce/apex/CheckWarehouseForWithOrderWithOrder.getPickListValuesIntoList';
import getOrderProformar  from '@salesforce/apex/CheckWarehouseForWithOrderWithOrder.getOrderProformar';
import checkInStockWarehous from '@salesforce/apex/CheckWarehouseForWithOrderWithOrder.checkInStockWarehous';
import insertItem from '@salesforce/apex/CheckWarehouseForWithOrderWithOrder.insertItem';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import ORDER_OBJECT from '@salesforce/schema/Order';
import { getRecord,getFieldValue } from 'lightning/uiRecordApi';
export default class CheckWareHouseWithOrder extends LightningElement {
    @track listValues = [{}];
    currentAccount = ''; 
    errorMsg = '';
    startDate;
    endDate;



    @api ObjSearchDTO = {
        startDate : null,
        endDate : null,
        strStatus : 'Place Order',
        strDODL : null
    };

    @track lstObjOrder = [];
    isData = false;
    allTotal = 0;
    isShowSpinner = false;
    isButtonSearch = false;
    isButtonSave = false;
    connectedCallback() {
        this.initDateFormat();
        this.getPicklist();   
    }


    @api recordId;
    @api objectApiName;

    @track objectInfo;
    strRecordTypeId;
    @wire(getObjectInfo, { objectApiName: ORDER_OBJECT })
    objectInfo({error, data}) {
        if(data) {
            const recordTypes = data.recordTypeInfos;
            console.log(JSON.stringify(recordTypes));
            for(var key in recordTypes) {
                console.log(recordTypes[key].recordTypeId);
                if(recordTypes[key].name  === 'Profomar Order') {
                    console.log(recordTypes[key].recordTypeId);
                    this.strRecordTypeId = recordTypes[key].recordTypeId;
                }
            }
        }
    }

    

    checkBox(event) {
        this.isButtonSearch = false;
        for(let i = 0; i < this.lstObjOrder.length; i++) {
            if(event.target.dataset.id == this.lstObjOrder[i].Id) {
                this.lstObjOrder[i].isChecked = event.target.checked;
            }
        }
        console.log(this.lstObjOrder);
        for(var i=0; i < this.lstObjOrder.length; i++) {
            if(this.lstObjOrder[i].isChecked) {
                this.isButtonSearch = true;
                break;
            }
        }
        for(var i=0; i < this.lstObjOrder.length;i++) {
            if(this.lstObjOrder[i].isChecked && this.lstObjOrder[i].InStock) {
                this.isButtonSave = true;
            }
            if(!this.lstObjOrder[i].InStock && this.lstObjOrder[i].isChecked) {
                this.isButtonSave = false;
                break;
            }
        }
    }

    checkAll(event) {
        this.isButtonSearch = false;
        const toggleList = this.template.querySelectorAll("[data-name='checkboxChild']");
        if(toggleList.length > 0) {
            for (const toggleElement of toggleList) {
                for(let i = 0; i < this.lstObjOrder.length; i++) {
                    if(toggleElement.dataset.id == this.lstObjOrder[i].Id) {
                        this.lstObjOrder[i].isChecked = event.target.checked;
                    }
                }
            }
        }

        for(var i=0; i < this.lstObjOrder.length; i++) {
            if(this.lstObjOrder[i].isChecked) {
                this.isButtonSearch = true;
                break;
            }
        }
        console.log(this.lstObjOrder);
    }

    checkProductWithWarehouse() {
        this.isShowSpinner = true;
        setTimeout(() => {
                checkInStockWarehous({
                    objSearch : this.ObjSearchDTO,
                    lstOrderChecked: this.lstObjOrder
                }).then(apiResponse => {
                    if(apiResponse.success) {
                        this.lstObjOrder = apiResponse.result;
                        this.isShowSpinner = false;
                        for(var i=0; i < this.lstObjOrder.length;i++) {
                            this.isButtonSave = true;
                            if(!this.lstObjOrder[i].InStock && this.lstObjOrder[i].isChecked) {
                                this.showToastMessage('please unchecked of record do not enough to condition back order.', 'Warning');
                                this.isButtonSave = false;
                                break;
                            }
                            
                        }
                        
                    } else {
                        this.isShowSpinner = false;
                        this.showToastMessage(apiResponse.error, 'Error');
                    }
                }).catch(error => {
                    this.isShowSpinner = false;
                    if(error) {
                        if (Array.isArray(error.body)) {
                            this.errorMsg = error.body.map(e => e.message).join(', ');
                        } else if (typeof error.body.message === 'string') {
                            this.errorMsg = error.body.message;
                        }
                    }
            })
        }, 5000);
    }

    lstOrderPassConditon = [];
    insertItem() {
        this.isShowSpinner = true;
        for(var i=0; i < this.lstObjOrder.length;i++) {
            if(this.lstObjOrder[i].isChecked) {
                this.lstOrderPassConditon.push(this.lstObjOrder[i]);
            }
        }
        setTimeout(() => {
            insertItem({
                    lstOrderInsert: this.lstOrderPassConditon
                }).then(apiResponse => {
                    if(apiResponse.success) {
                        this.isShowSpinner = false;
                        this.showToastMessage('Save successfully!', 'success');
                    } else {
                        this.isShowSpinner = false;
                        this.showToastMessage(apiResponse.error, 'Error');
                    }
                }).catch(error => {
                    this.isShowSpinner = false;
                    if(error) {
                        if (Array.isArray(error.body)) {
                            this.errorMsg = error.body.map(e => e.message).join(', ');
                        } else if (typeof error.body.message === 'string') {
                            this.errorMsg = error.body.message;
                        }
                    }
            })
        }, 5000);
    }

    hideAndShow(event) {
        let indx = event.target.dataset.recordId;
        if (this.lstObjOrder) {
            let recs = JSON.parse(JSON.stringify(this.lstObjOrder));
            if(recs[indx].lstOrderItem.length > 0) {
                if(recs[indx].hideButton) {
                    recs[indx].hideButton = false;
                } else {
                    recs[indx].hideButton = true;
                }
            } else {
                this.showToastMessage('Order này chưa được add product vào', 'warning');
                return;
            }
            
            this.lstObjOrder = recs;
            console.log('After Change ' + this.lstObjOrder[indx].hideButton);
        }
        if (event.target.label === "-") {
            event.target.label = "+";
        } else {
            event.target.label = "-";
        }
    }

    SearchingByCondition() {
        this.isShowSpinner = true;
        this.isData = false;
        this.lstObjOrder = [];
        this.allTotal = 0 ;
        console.log(this.ObjSearchDTO);
        this.isButtonSave = false;
        setTimeout(() => {
            getOrderProformar({
                objSearch : this.ObjSearchDTO
            }).then(apiResponse => {
                if(apiResponse.success) {
                    this.isShowSpinner = false;
                    this.lstObjOrder = apiResponse.result;
                    this.lstObjOrder.forEach(element => {
                        element.URLOrder = window.location.origin + '/' + element.Id;
                    });
                    this.isData = true;
                    this.allTotal = this.lstObjOrder.length;
                    
                    
                } else {
                    this.isShowSpinner = false;
                    this.showToastMessage(apiResponse.error, 'Error');
                }
            })
            .catch(error => {
                if(error) {
                    this.isShowSpinner = false;
                    if (Array.isArray(error.body)) {
                        this.errorMsg = error.body.map(e => e.message).join(', ');
                    } else if (typeof error.body.message === 'string') {
                        this.errorMsg = error.body.message;
                    }
                }
            })
        }, 100);
    }

    handleChange(event) {
        if(event.target.dataset.id === 'StartDate'){
            this.ObjSearchDTO.startDate = event.target.value;
        } else if(event.target.dataset.id === 'EndDate') {
            this.ObjSearchDTO.endDate = event.target.value;
        } else if(event.target.dataset.id === 'Status') {
            this.ObjSearchDTO.strStatus = event.target.value;
        } else if(event.target.dataset.id === 'DODL') {
            this.ObjSearchDTO.strDODL = event.target.value;
        }
        console.log(this.ObjSearchDTO);
    }

    initDateFormat() {
		var dateProcess = new Date();
		var dd = String(1).padStart(2, '0');
		var mm = String(dateProcess.getMonth() + 1).padStart(2, '0');
		var yyyy = dateProcess.getFullYear();
		var lastDate = new Date(yyyy, mm, 1 - 1);
		this.ObjSearchDTO.startDate = [yyyy, mm, dd].join('-');
		this.ObjSearchDTO.endDate = [yyyy, mm, lastDate.getDate()].join('-');

		// var today = new Date();
		// var dd = String(today.getDate()).padStart(2, '0');
		// var mm = String(today.getMonth() + 1).padStart(2, '0');
		// var yyyy = today.getFullYear();
		// today = [yyyy, mm, dd].join('-');
		// component.set('v.dateProcess', today);
	}

    getPicklist() {
        getPickListValuesIntoList().then(apiResponse => {
                if(apiResponse.success) {
                    let options = [];
                    for(var key in apiResponse.result){
                        let option = {
                            label: apiResponse.result[key].Name,
                            value: apiResponse.result[key].Id
                        };
                        options.push(option);
                    }
                    this.listValues = options
                    console.log(JSON.stringify(this.listValues));
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

    showToastMessage(msg, type) {
        this.dispatchEvent(
            new ShowToastEvent({
                variant: type,
                message: msg
            })
        );
    }
}