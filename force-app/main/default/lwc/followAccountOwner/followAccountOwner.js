import { LightningElement ,api, wire, track} from 'lwc';      
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getUserById from '@salesforce/apex/ReassignAccountOwner.getUserById';
import getAccountDTO from '@salesforce/apex/ReassignAccountOwner.getAccountDTO';
import updateOwnerAllObjectRelatedToAccount from '@salesforce/apex/ReassignAccountOwner.updateOwnerAllObjectRelatedToAccount';
export default class FollowAccountOwner extends LightningElement {
    @api productList ;
    @track benifitList ;
    @track bShowModal = false;
    @api selectedProduct = '';
    @track errorMsg = '';
    @api recordId;
    @track recordIdOwnerId;
    @track userNameChoosen;
    @track disabledButton = false;
    disabledButtonStep1 = true;
    disabledButtonStep2 = true;
    @track currentStep = '1';
    @track lstStrPriceBook = [];
    isShowSpinner = false;

    handleOnStepClick(event) {
        this.currentStep = event.target.value;
    }

    connectedCallback() {
        this.userList();
    }
 
    get isStepOne() {
        return this.currentStep === "1";
    }
 
    get isStepTwo() {
        return this.currentStep === "2";
    }
 
    get isEnableNext() {
        return this.currentStep != "3";
    }
 
    get isEnablePrev() {
        return this.currentStep != "1";
    }
 
 
    handleNext1(){
        if(this.currentStep == "1"){
            let rowindex = 1;
            let listMember = [];
            this.productList= [];
            getAccountDTO({
                recordId: this.recordId
            }).then(apiResponse => {
                if(apiResponse.success) {
                    const result = apiResponse.result;
                    listMember.push(result);
                    this.productList = listMember;
                    console.log(this.productList);
                } else {
                    this.showToastMessage(apiResponse.error, 'Error');
                }
            })
            .catch(error => {
                this.productList = '';
                if(error) {
                    if (Array.isArray(error.body)) {
                        this.errorMsg = error.body.map(e => e.message).join(', ');
                    } else if (typeof error.body.message === 'string') {
                        this.errorMsg = error.body.message;
                    }
                }
            })
            this.currentStep = "2";
        }
    }

    

    handleNext2(){
        this.isShowSpinner = true;
        setTimeout(() => {
            updateOwnerAllObjectRelatedToAccount({
                recordId: this.recordId,
                recordIdOwnerId : this.recordIdOwnerId
            }).then(apiResponse => {
                this.isShowSpinner = false;
                if(apiResponse.success) {
                    this.showToastMessage('Save successfully!', 'success');
                    this.closeQuickAction();
                    location.reload();
                } else {
                    this.showToastMessage(apiResponse.error, 'Error');
                }
            })
            .catch(error => {
                this.isShowSpinner = false;
                this.productList = '';
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
 
    handlePrev(){
        if(this.currentStep = "2"){
            this.disabledButtonStep1 = true;
            this.currentStep = "1";
        }
    }

    @track items = []; //this holds the array for records with value & label
    @track error;
    @track value;

    userList(){
        var lstUsers = [];
        getUserById({
            recordId: this.recordId,
        }).then(apiResponse => {
            if(apiResponse.success) {
                const data = apiResponse.result;
                data.forEach(element => {
                    var obj = {
                        value : element.Id,
                        label : element.Name
                    };
                    lstUsers.push(obj)
                });
                this.items = lstUsers;
                console.log(this.items);
            } else {
                this.showToastMessage(apiResponse.error, 'Error');
            }
        })
        .catch(error => {
            this.items = '';
            if(error) {
                if (Array.isArray(error.body)) {
                    this.errorMsg = error.body.map(e => e.message).join(', ');
                } else if (typeof error.body.message === 'string') {
                    this.errorMsg = error.body.message;
                }
            }
        })
    }
    get pricebookOptions(){
        return this.items;
    }
    pricebookChange(event) {
        this.disabledButtonStep1 = true;
        if(event.detail.value) {
            console.log(event.detail.value);
            this.recordIdOwnerId = event.detail.value;
            this.disabledButtonStep1 = false;
        }
    }

    closeQuickAction() {
        const closeQA = new CustomEvent('close');
        // Dispatches the event.
        this.dispatchEvent(closeQA);
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

    setBoxes(){
        const boxes = this.template.querySelectorAll('lightning-input');
        this.lstStrPriceBook = [];
        this.disabledButtonStep2 = true;
        for(let i = 0; i < boxes.length; i++) {
            if(boxes[i].checked) {
                this.disabledButtonStep2 = false;
            }
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
}