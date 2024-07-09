import { LightningElement, wire } from "lwc";
import { CurrentPageReference } from "lightning/navigation";
import unsubscribeEmail from "@salesforce/apex/WidgetUnsubscribeEmailController.unsubscribeEmail";

export default class WidgetUnsubscribeEmail extends LightningElement {
  email = "";
  processed = false;
  processing = false;
  message = "Hủy đăng kí nhận tin thành công!";

  @wire(CurrentPageReference)
  getStateParameters(currentPageReference) {
    if (currentPageReference) {
      this.email = currentPageReference.state?.email;
    }
  }

  async handleUnsubscribe() {
    this.processing = true;
    let reg = /[^\s@]+@[^\s@]+\.[^\s@]+/;
    if (reg.test(this.email)) {
      try {
        let result = await unsubscribeEmail({ email: this.email });
        console.log(result);
      } catch (error) {
        console.log(error);
      }
    }
    this.processing = false;
    this.processed = true;
  }
}
