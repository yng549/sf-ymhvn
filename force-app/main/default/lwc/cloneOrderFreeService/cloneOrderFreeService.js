import { LightningElement, wire, track, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from 'lightning/navigation';
import cloneOrderAndItem from "@salesforce/apex/CloneOrderFreeServiceController.cloneOrderAndItem";
export default class CloneOrderFreeService extends NavigationMixin(LightningElement) {
  @api recordId;
  @api orderDTO;
  @track errorMsg = "";

  isShowSpinner = false;
  connectedCallback() {}

  showToastMessage(msg, type) {
    this.dispatchEvent(
      new ShowToastEvent({
        variant: type,
        message: msg
      })
    );
  }
  saveOrder() {
    this.isShowSpinner = true;

    let data = JSON.parse(JSON.stringify(this.orderDTO));

    data.AccountId = this.template.querySelector(
      "[data-field='AccountId']"
    ).value;

    data.MileageIn = this.template.querySelector(
      "[data-field='Mileage__c']"
    ).value;

    data.OrderStartDate = this.template.querySelector(
      "[data-field='EffectiveDate']"
    ).value;
    data.Status = this.template.querySelector("[data-field='Status']").value;
    data.Asset = this.template.querySelector("[data-field='Asset__c']").value;
    data.RequestDescription = this.template.querySelector(
      "[data-field='Request_Description__c']"
    ).value;
    data.MileageOut = this.template.querySelector(
      "[data-field='Mileage_Out__c']"
    ).value;
    data.ServiceConsultant = this.template.querySelector(
      "[data-field='Cashier__c']"
    ).value;
    data.Mechanic = this.template.querySelector(
      "[data-field='Mechanic__c']"
    ).value;
    data.DetailingStaff = this.template.querySelector(
      "[data-field='Detailing_Staff__c']"
    ).value;
    data.RequestFrom = this.template.querySelector(
      "[data-field='Request_From__c']"
    ).value;
    data.ApprovalStatus = this.template.querySelector(
      "[data-field='Approval_Status__c']"
    ).value;

    // const clone = { ...data };
  
    cloneOrderAndItem({
      jsonOrderDTO: JSON.stringify(data),
    })
      .then((apiResponse) => {
        this.isShowSpinner = false;
        if (apiResponse.success) {
          const result = apiResponse.result;
          console.log(result.Id);
          this.showToastMessage("Save successfully!", "success");
          this.navigateToViewOrderPage(result.Id);
          this.dispatchEvent(new CustomEvent("recordChange"));  
          this.closeQuickAction();
     
        } else {
          this.showToastMessage(apiResponse.error, "Error");
        }
      })
      .catch((error) => {
        this.isShowSpinner = false;
        this.productList = "";
        if (error) {
          if (Array.isArray(error.body)) {
            this.errorMsg = error.body.map((e) => e.message).join(", ");
          } else if (typeof error.body.message === "string") {
            this.errorMsg = error.body.message;
          }
          console.log(this.errorMsg);
          this.showToastMessage(this.errorMsg, "Error");
        }
      });
  }

  closeQuickAction() {
    const closeQA = new CustomEvent("close");
    // Dispatches the event.
    this.dispatchEvent(closeQA);
  }
 
   // Navigate to View Order Page
   navigateToViewOrderPage(strId) {
    this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: {
            recordId: strId,
            objectApiName: 'Order',
            actionName: 'view'
        },
    });
}
}