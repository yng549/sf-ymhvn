import { LightningElement ,track, api} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import GetCampaignDMSRecall from '@salesforce/apex/GetCampaignDMSRecall.GetCampaignDMSRecall';
import ORDER_OBJECT from '@salesforce/schema/Order';
import STATUS from '@salesforce/schema/Order.Status';
import ACCOUNTNAME from '@salesforce/schema/Order.AccountId';
import { CloseActionScreenEvent } from 'lightning/actions';
import createOrder from '@salesforce/apex/GetCampaignDMSRecall.createOrder';
import GetAsset from '@salesforce/apex/GetCampaignDMSRecall.GetAsset';
import fetchRecords from '@salesforce/apex/SearchController.fetchRecords';

export default class TabCampaignRecall extends LightningElement {
    @track isShowSpinner = false;
    @track flagButton = false;
    @track bShowModal = false;
    @track framenumber = '';
    @track lstCampaignAsset;
    @api dttoday;
    @api recordIdCampaign;
    @api AssetId;
    @api orderObject = ORDER_OBJECT;
    @api orderSelelect;
    @api myFields = [STATUS, ACCOUNTNAME];
    @api objAsset;
    urlAssetId = '';
    @api statusOrder = 'Draft';
    flagSearch = false;
    @track status= [
        {'label': 'Draft', 'value': 'Draft'},
        {'label': 'Deal Sheet', 'value': 'Deal Sheet'},
    ];
    @api objOrderCreated;

    //LookupSearch
    @api objectName = 'Asset';
    @api fieldName = 'Frame_Number__c';
    @api value;
    @api iconName = 'standard:account';
    @api label;
    @api placeholder;
    @api className;
    @api required = false;
    @track searchString;
    @track selectedRecord;
    @track recordsList;
    @track message;
    @track showPill = false;
    @track showSpinner = false;
    @track showDropdown = false;
    

    connectedCallback() {
        if(this.value)
            this.fetchData();
    }
    searchRecords(event) {
        this.searchString = event.target.value;
        if(this.searchString) {
            this.fetchData();
        } else {
            this.showDropdown = false;
        }
    }

    selectItem(event) {
        this.flagButton = false;
        if(event.currentTarget.dataset.key) {
    		var index = this.recordsList.findIndex(x => x.value === event.currentTarget.dataset.key)
            if(index != -1) {
                
                this.selectedRecord = this.recordsList[index];
                this.framenumber = this.recordsList[index].label;
                this.value = this.selectedRecord.value;
                this.showDropdown = false;
                this.showPill = true;
            }
            if(this.framenumber) {
                this.flagButton = true;
            }
            console.log('this.selectedRecord', this.selectedRecord);
            console.log('this.framenumber', this.framenumber);
        }
    }

    removeItem() {
        this.showPill = false;
        this.value = '';
        this.selectedRecord = '';
        this.searchString = '';
    }

    showRecords() {
        if(this.recordsList && this.searchString) {
            this.showDropdown = true;
        }
    }

    blurEvent() {
        this.showDropdown = false;
    }

    fetchData() {
        this.showSpinner = true;
        this.message = '';
        this.recordsList = [];
        fetchRecords({
            objectName : this.objectName,
            filterField : this.fieldName,
            searchString : this.searchString,
            value : this.value
        })
        .then(result => {
            if(result && result.length > 0) {
                if(this.value) {
                    this.selectedRecord = result[0];
                    this.showPill = true;
                } else {
                    this.recordsList = result;
                }
            } else {
                this.message = "No Records Found for '" + this.searchString + "'";
            }
            this.showSpinner = false;
        }).catch(error => {
            this.message = error.message;
            this.showSpinner = false;
        })
        if(!this.value) {
            this.showDropdown = true;
        }
    }
    //LookupSearch

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleAccountCreated(){
        // Run code when account is created.
    }

    changeStatus(event) {
        this.statusOrder = '';
        var status = event.target.value;
        this.statusOrder = status;
    }

    closeXPopup() {
        this.bShowModal = false;
    }

    hideAndShow(event) {
        let indx = event.target.dataset.recordId;
        if (this.lstCampaignAsset) {
            let recs = JSON.parse(JSON.stringify(this.lstCampaignAsset));
            if(recs[indx].lstCampaignAsset.length > 0) {
                recs[indx].hideBool = !recs[indx].hideBool;
            } else {
                this.showToastMessage('Số khung này chưa tham gia chiến dịch recall !', 'warning');
                return;
            }
            
            this.lstCampaignAsset = recs;
            console.log('After Change ' + this.lstCampaignAsset[indx].hideBool);
        }
        if (event.target.label === "-") {
            event.target.label = "+";
        } else {
            event.target.label = "-";
        }
    }

    closePopup() {
        this.bShowModal = false;
        this.flagButton = false;
        this.framenumber = '';
        this.flagSearch = false;
        this.lstCampaignAsset = [];
        let selectedRows = this.template.querySelectorAll('lightning-input');
        // based on selected row getting values of the contact
        for(let i = 0; i < selectedRows.length; i++) {
            if(selectedRows[i].value && selectedRows[i].type === 'text' && selectedRows[i].name === 'framenumber') {
                if(selectedRows[i].value) {
                    selectedRows[i].value = '';
                }
            } else if(selectedRows[i].checked && selectedRows[i].type === 'checkbox') {
                selectedRows[i].checked = false;
            }
        }
    }

    

    changeValue() {
        this.flagButton = false;
        let selectedRows = this.template.querySelectorAll('lightning-input');
        // based on selected row getting values of the contact
        for(let i = 0; i < selectedRows.length; i++) {
            if(selectedRows[i].value && selectedRows[i].type === 'text') {
                if(selectedRows[i].name === 'framenumber') {
                    if(selectedRows[i].value) {
                      this.framenumber = selectedRows[i].value;
                    }
                }
            }
        }
        if(this.framenumber) {
            this.flagButton = true;
        }
    }

    connectedCallback(){
        let rightNow = new Date();
        rightNow.setMinutes(
            new Date().getMinutes() - new Date().getTimezoneOffset()
        );
        let yyyyMmDd = rightNow.toISOString().slice(0,10);
        this.dttoday = yyyyMmDd;
        console.log(this.dttoday);
    }

    setBoxes(event){
        this.orderSelelect = '';
        this.recordIdCampaign = '';
        this.AssetId = '';
        const boxes = this.template.querySelectorAll('lightning-input');
        boxes.forEach(box => box.checked = event.target.name === box.name);
        let selectedRows = this.template.querySelectorAll('lightning-input');
        for(let i = 0; i < boxes.length; i++) {
            if(selectedRows[i].checked && selectedRows[i].type === 'checkbox') {
                this.lstCampaignAsset.forEach(element => {
                    if(element.lstCampaignAsset.length == 0 && element.Id === selectedRows[i].value && !element.checkJoined) {
                        this.bShowModal = true;
                        this.recordIdCampaign = element.Id;
                        this.AssetId = element.strAssetId;
                        this.orderSelelect = element;
                    } else if(element.lstCampaignAsset.length > 0 && element.Id === selectedRows[i].value && !element.checkJoined){
                        this.showToastMessage('Số khung này đã tham gia chương trình. Nhấn expand để biết thêm chi tiết !', 'error');
                    }
                });
                break;
            }
        }
    }

    saveOrder() {
        let strDescription = this.template.querySelector('lightning-textarea').value;
        let statusOrder = this.statusOrder;
        this.isShowSpinner = true;
        setTimeout(() => {
            createOrder({
                recordId : this.recordIdCampaign,
                strAssetId : this.AssetId,
                strStatus: statusOrder,
                strDescription: strDescription
            }).then(apiResponse => {
                this.isShowSpinner = false;
                if(apiResponse.success) {
                    this.isShowSpinner = false;
                    this.objOrderCreated = apiResponse.result;
                    this.bShowModal = false;
                    var strUrl = window.location.origin + '/' + this.objOrderCreated.Id;
                    console.log('strUrl ' + strUrl);
                    const event = new ShowToastEvent({
                        title: 'Success!',
                        variant: 'Success',
                        message: 'Record OrderNumber {0} created! See it {1}!',
                        messageData: [
                            this.objOrderCreated.OrderNumber,
                            {
                                url: strUrl,
                                label: 'click here',
                                target: '_blank',
                            },
                        ],
                    });
                    this.dispatchEvent(event);
                    setTimeout(() => {
                        location.reload();
                    }, 8000);
                } else {
                    this.isShowSpinner = false;
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
        }, 300);
        this.bShowModal = false;
        // based on selected row getting values of the contact
        
    }

    showToastMessage(msg, type) {
        this.dispatchEvent(
            new ShowToastEvent({
                variant: type,
                message: msg
            })
        );
    }

    searchFrameNumber() {
        this.lstCampaignAsset = [];
        this.isShowSpinner = true;
        let rowIndex = 1;
        this.objAsset = '';
        setTimeout(() => {
            GetAsset({
                strFrameNumber : this.framenumber
            }).then(apiResponse => {
                this.isShowSpinner = false;
                if(apiResponse.success) {
                    this.flagSearch = true;
                    const data = apiResponse.result;
                    this.objAsset = data.objAsset;
                    this.urlAssetId = window.location.origin + '/' + data.objAsset.Id
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
        }, 100);


        setTimeout(() => {
            GetCampaignDMSRecall({
                strFrameNumber : this.framenumber
            }).then(apiResponse => {
                this.isShowSpinner = false;
                if(apiResponse.success) {
                    this.lstCampaignAsset = apiResponse.result;
                    this.lstCampaignAsset.forEach(element => {
                        element.URLCampaignAsset = window.location.origin + '/' + element.Id;
                        element.OrderBy = rowIndex ++;
                        element.hideBool = true;
                        if(element.lstCampaignAsset.length > 0) {
                            element.lstCampaignAsset.forEach(i => {
                                i.UrlOrder = window.location.origin + '/' + i.Order__c;
                            });
                        }
                    });
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

        
    }

    
}