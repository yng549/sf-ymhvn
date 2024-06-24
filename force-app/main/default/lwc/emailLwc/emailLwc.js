import { LightningElement, track, api} from "lwc";
import sendEmailController from "@salesforce/apex/EmailClass.sendEmailController";
import getOpportunity from "@salesforce/apex/EmailClass.getOpportunity";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class EmailLwc extends LightningElement {
    toAddress = [];
    ccAddress = [];
    subject = "";
    body = "";
    @api recordId;
    isShowSpinner = false;
    toEmail;

    @track files = [];

    wantToUploadFile = false;

    connectedCallback() {
        this.getOpportunityInit();
    }

    getOpportunityInit() {
        getOpportunity({
            recordId: this.recordId
        }).then(apiResponse => {
                if(apiResponse.success) {
                    this.toEmail = apiResponse.result.Account.PersonEmail;
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
    
    toggleFileUpload() {
        this.wantToUploadFile = !this.wantToUploadFile;
    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        console.log("uploadedFiles", uploadedFiles);
        this.files = [...this.files, ...uploadedFiles];
        this.wantToUploadFile = false;
    }

    handleRemove(event) {
        const index = event.target.dataset.index;
        this.files.splice(index, 1);
    }

    handleToAddressChange(event) {
        this.toAddress = event.detail.selectedValues;
    }

    handleCcAddressChange(event) {
        this.ccAddress = event.detail.selectedValues;
    }

    handleSubjectChange(event) {
        this.subject = event.target.value;
    }

    handleBodyChange(event) {
        this.body = event.target.value;
    }

    validateEmails(emailAddressList) {
        let areEmailsValid;
        if(emailAddressList.length > 1) {
            areEmailsValid = emailAddressList.reduce((accumulator, next) => {
                const isValid = this.validateEmail(next);
                return accumulator && isValid;
            });
        }
        else if(emailAddressList.length > 0) {
            areEmailsValid = this.validateEmail(emailAddressList[0]);
        }
        return areEmailsValid;
    }

    validateEmail(email) {
        console.log("In VE");
        const res = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()s[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
        console.log("res", res);
        return res.test(String(email).toLowerCase());
    }

    handleReset() {
        this.toAddress = [];
        this.ccAddress = [];
        this.subject = "";
        this.body = "";
        this.files = [];
        this.template.querySelectorAll("c-email-input").forEach((input) => input.reset());
    }

    errorMsg = '';
    handleSendEmail() {

        let emailDetails = {
            toAddress: this.toAddress,
            ccAddress: this.ccAddress,
            subject: this.subject,
            body: this.body,
            files: this.files
        };
        console.log("emailDetails", emailDetails);
        this.isShowSpinner = true;
        setTimeout(() => {
            sendEmailController({
                emailDetailStr: JSON.stringify(emailDetails),
                recordId: this.recordId
            }).then(apiResponse => {
                this.isShowSpinner = false;
                if(apiResponse.success) {
                    this.showToastMessage('Send successfully!', 'success');
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
            }, 50);

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