import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import searchProductPCA from "@salesforce/apex/CheckStockPCAController.searchProductPCA";

export default class CheckStockPCA extends LightningElement {
  lst;
  errorMsg = "";
  isData = false;
  @track allFilteredClients;
  doneTypingInterval = 800;
  typingTimer;

  connectedCallback() {
    this.handleFilter();
  }
  
  handleFilter() {
    let rowIndex = 1;
    this.isShowSpinner = true;
    clearTimeout(this.typingTimer);
    this.typingTimer = setTimeout(() => {
      let inputValue = this.template.querySelector("[data-name='searchProd']");
      this.allFilteredClients = [];
      searchProductPCA({ key : inputValue.value})
        .then((apiResponse) => {
          if (apiResponse.success) {
            this.isShowSpinner = false;
            const data = apiResponse.result;
            data.forEach((element) => {
              element.URLProduct2 = window.location.origin + "/" + element.Id;
              element.OrderBy = rowIndex++;
            });
            this.allFilteredClients = data;
            console.log(this.allFilteredClients);
          } else {
            this.isShowSpinner = false;
            this.showToastMessage(apiResponse.error, "Error");
 
          }
        })
        .catch((error) => {
          this.isShowSpinner = false;
          if (error) {
            if (Array.isArray(error.body)) {
              this.errorMsg = error.body.map((e) => e.message).join(", ");
            } else if (typeof error.body.message === "string") {
              this.errorMsg = error.body.message;
            }
          }
        });
        this.isShowSpinner = false;  }, this.doneTypingInterval);
  }

  closeQuickAction() {
    const closeQA = new CustomEvent("close");
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