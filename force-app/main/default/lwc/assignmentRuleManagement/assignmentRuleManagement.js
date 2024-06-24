import {
  LightningElement,
  api,
  track
} from 'lwc';
import {
  ShowToastEvent
} from 'lightning/platformShowToastEvent';
import {
  removeNamespacePrefixFromData
} from 'c/fieldUtils';

import apexGetInitialData from '@salesforce/apex/AssignmentRuleManagementController.getInitialData';
import apexSaveRule from '@salesforce/apex/AssignmentRuleManagementController.saveRule';

const allowedCustomLogicCharacterRegex = new RegExp(/[^0-9|AND|OR|(|)|\s]/, 'g');

export default class AssignmentRuleManagement extends LightningElement {
  @api recordId;
  @api type;

  @track initialized;
  @track inputAction;
  @track inputCustomLogic;
  @track rules = [];
  @track assignment;
  @track picklist;
  @track isLoading;
  @track _helpMessage;
  @track namespacePrefix;

  _actionOptions = [{
    label: 'All Conditions Are Met',
    value: 'And'
  }, {
    label: 'Any Condition Is Met',
    value: 'Or'
  }];

  connectedCallback() {
    apexGetInitialData({
      recordId: this.recordId,
      type: this.type
    }).then(response => {
      if (response && response.success) {
        const result = response.result;

        this.namespacePrefix = result.namespacePrefix;

        if (result.assignment) {
          this.assignment = result.assignment;
          if (this.type === 'Assignment Rule') {
            this.inputAction = this.assignment.Assignment_Rule_Type__c;
            this.inputCustomLogic = this.assignment.Custom_Assignment_Rule_Order__c;
          }
          if (this.type === 'Re-Assignment Rule') {
            this.inputAction = this.assignment.Auto_Reassign_Rule_Type__c;
            this.inputCustomLogic = this.assignment.Custom_Auto_Reassign_Rule_Order__c;
          }
        }

        if (result.rules && result.rules.length > 0) {
          this.rules = result.rules;
        } else {
          this.handleAddMoreCondition();
        }
      }

      if (!this.inputAction) {
        this.inputAction = this._actionOptions[0].value;
      }

      this.initialized = true;
    });
  }

  handleAddMoreCondition() {
    if (!this.rules) {
      this.rules = [];
    }
    this.rules.push({
      Sort_Order__c: this.rules.length + 1
    });
  }

  handleDeleteCondition(event) {
    event.stopPropagation();
    if (event.detail && !isNaN(event.detail.index)) {
      this.rules.splice(event.detail.index, 1);
    }
  }

  handleInputChange(event) {
    this[event.target.name] = event.target.value;
  }

  handleSave() {
    if (!this.isLoading) {
      this.isLoading = true;
      this._helpMessage = '';
      const rules = [];
      let isValid = true;
      this.getAllRuleItemElement().forEach(el => {
        if (el.checkValidity()) {
          rules.push(el.getRule());
        } else {
          isValid = false;
        }
      });

      if (this.showCustomLogic) {
        if (!this.inputCustomLogic) {
          this._helpMessage = 'Invalid condition logic: Some filter conditions are defined but not referenced in your filter logic.';
          isValid = false;
        }
        if (allowedCustomLogicCharacterRegex.test(this.inputCustomLogic)) {
          this._helpMessage = 'Invalid condition logic: Check the spelling in your filter logic.';
          isValid = false;
        }
      }

      if (isValid) {
        apexSaveRule({
          recordId: this.recordId,
          type: this.type,
          ruleType: this.inputAction,
          customRuleLogic: this.inputCustomLogic,
          rules: rules
        }).then(response => {
          if (response && response.success) {
            this.showToastMessage('success', 'Success!', 'Save rule successfully.');
          } else {
            if (response && response.error) {
              this.showToastMessage('error', '', response.error);
            } else {
              this.showToastMessage('error', '', 'Failed to save rule.');
            }
          }
          this.isLoading = false;
        }).catch(e => {
          // eslint-disable-next-line no-console
          console.error(e);
          this.showToastMessage('error', '', 'Failed to save rule.');
          this.isLoading = false;
        });
      } else {
        this.isLoading = false;
      }
    }
  }

  getAllRuleItemElement() {
    return [...this.template.querySelectorAll('c-assignment-rule-item')];
  }

  showToastMessage(variant, title, message) {
    const toastEvent = new ShowToastEvent({
      variant: variant,
      title: title,
      message: message,
    });
    this.dispatchEvent(toastEvent);
  }

  get showCustomLogic() {
    return this.inputAction === 'Custom';
  }

  get getCustomLogic() {
    if (this.assignment) {
      if (this.type === 'Assignment Rule' && this.assignment.Custom_Assignment_Rule_Order__c) {
        return this.assignment.Custom_Assignment_Rule_Order__c;
      }
      if (this.type === 'Re-Assignment Rule' && this.assignment.Custom_Auto_Reassign_Rule_Order__c) {
        return this.assignment.Custom_Auto_Reassign_Rule_Order__c;
      }
    }

    return '';
  }
}