import {
    LightningElement,
    api,
    track,
    wire
} from 'lwc';
import {
    getPicklistValuesByRecordType,
    getObjectInfo
} from 'lightning/uiObjectInfoApi';

import {
    FIELD_TYPES,
    SUPPORTED_FIELD_TYPES,
    getFieldInfo
} from 'c/fieldUtils'

const MASTER_RECORD_TYPE_ID = '012000000000000AAA';

export default class AssignmentRuleItem extends LightningElement {
    @api item;
    @api actionType;
    @api schema;
    @api itemIndex;
    @api objectApiName;

    @track schema;
    @track currentFieldInfo = null;
    @track picklistOperator = [];
    @track currentFieldPicklist = [];
    @track currentOperator = null;

    _objectInfo = null;
    _wiredPicklistApiName = null;
    _wiredRecordTypeId = null;

    picklistBoolean = [{
        label: 'True',
        value: 'true'
    }, {
        label: 'False',
        value: 'false'
    }];

    @wire(getObjectInfo, {
        objectApiName: "$objectApiName"
    })
    wiredObjectSchema(value) {
        this.handleObjectSchema(value);
    }

    @wire(getPicklistValuesByRecordType, {
        objectApiName: '$_wiredPicklistApiName',
        recordTypeId: '$_wiredRecordTypeId'
    })
    wiredPicklistValuesByRecordType(value) {
        this.handlePicklistValues(value);
    }

    connectedCallback() {}

    triggerPicklistWire() {
        const oldRecordTypeId = this._wiredRecordTypeId;
        const oldObjectApiName = this._wiredPicklistApiName;

        this._wiredPicklistApiName = this.objectApiName;
        this._wiredRecordTypeId = MASTER_RECORD_TYPE_ID;

        if (oldObjectApiName === this._wiredPicklistApiName && oldRecordTypeId === this._wiredRecordTypeId) {
            this.handlePicklistValues(this._wiredPicklistValues);
        }
    }

    triggerLoadEvent() {
        const fieldInfo = getFieldInfo(this.item.Field_Name__c, this._objectInfo);

        if (
            fieldInfo.dataType === FIELD_TYPES.PICKLIST ||
            fieldInfo.dataType === FIELD_TYPES.MULTI_PICKLIST
        ) {
            this.currentFieldPicklist = this._picklistFieldValues[fieldInfo.apiName] ? this._picklistFieldValues[fieldInfo.apiName].values : [];
        }

        this.currentFieldInfo = fieldInfo;
        this.picklistOperator = this.getPicklistOperator();
        this.currentOperator = this.item.Operator__c;
        if (this.isContainsPicklistOperator) {
            this.currentConditionValue = this.item.Condition__c ? this.item.Condition__c.split(',') : [];
        } else {
            this.currentConditionValue = this.item.Condition__c;
        }
    }

    handleObjectSchema({
        error,
        data
    }) {
        if (error) {
            this.handleErrors(error);
        }

        // Get object fields
        if (data) {
            this._objectInfo = data;
            this.schema = [];
            for (let key of Object.keys(data.fields)) {
                const fieldInfo = data.fields[key];
                // Only use field that in the list of supported field types (ex: string value, number value ...)
                if (SUPPORTED_FIELD_TYPES.indexOf(fieldInfo.dataType) >= 0) {
                    this.schema.push({
                        label: fieldInfo.label,
                        value: fieldInfo.apiName
                    });
                }
            }
            this.triggerPicklistWire();
        }
    }

    handlePicklistValues(value) {
        this._wiredPicklistValues = value;

        const {
            error,
            data
        } = value;

        if (error) {
            this.handleErrors(error);
        }

        if (!data) {
            return;
        }

        this._picklistFieldValues = data.picklistFieldValues || data;
        this.triggerLoadEvent();
    }

    handleInputChange(event) {
        this[event.target.name] = event.target.value;
    }

    handleFieldChange(event) {
        const fieldInfo = getFieldInfo(event.target.value, this._objectInfo);

        if (
            fieldInfo.dataType === FIELD_TYPES.PICKLIST ||
            fieldInfo.dataType === FIELD_TYPES.MULTI_PICKLIST
        ) {
            this.currentFieldPicklist = this._picklistFieldValues[fieldInfo.apiName] ? this._picklistFieldValues[fieldInfo.apiName].values : [];
        }
        this.currentFieldInfo = fieldInfo;
        this.picklistOperator = this.getPicklistOperator();
        this.currentOperator = '';
        this.currentConditionValue = '';
    }

    handleOperatorChange(event) {
        this.currentOperator = event.target.value;
    }

    handleDeleteCondition() {
        const index = this.itemIndex;
        this.dispatchEvent(
            new CustomEvent('removecondition', {
                detail: {
                    index: index
                }
            })
        );
    }

    handleErrors(error) {
        // eslint-disable-next-line no-console
        console.error(error);
    }

    getPicklistOperator() {
        if (this.currentFieldInfo) {
            // Default operator
            const picklistOperator = [{
                    value: 'Is Null',
                    label: 'Is Null'
                }, {
                    value: 'Equals',
                    label: 'Equals'
                },
                {
                    value: 'Does Not Equal',
                    label: 'Does Not Equal'
                },
                {
                    value: 'Contains',
                    label: 'Contains'
                }
            ];

            if (
                this.currentFieldInfo.dataType === FIELD_TYPES.CURRENCY ||
                this.currentFieldInfo.dataType === FIELD_TYPES.DOUBLE ||
                this.currentFieldInfo.dataType === FIELD_TYPES.DECIMAL ||
                this.currentFieldInfo.dataType === FIELD_TYPES.PERCENT ||
                this.currentFieldInfo.dataType === FIELD_TYPES.INT ||
                this.currentFieldInfo.dataType === FIELD_TYPES.DATE ||
                this.currentFieldInfo.dataType === FIELD_TYPES.DATETIME
            ) {
                picklistOperator.push({
                    value: 'Greater Than',
                    label: 'Greater Than'
                });
                picklistOperator.push({
                    value: 'Less Than',
                    label: 'Less Than'
                });
            }

            if (
                this.currentFieldInfo.dataType === FIELD_TYPES.ADDRESS ||
                this.currentFieldInfo.dataType === FIELD_TYPES.RICH_TEXTAREA ||
                this.currentFieldInfo.dataType === FIELD_TYPES.EMAIL ||
                this.currentFieldInfo.dataType === FIELD_TYPES.PLAIN_TEXTAREA ||
                this.currentFieldInfo.dataType === FIELD_TYPES.PHONE ||
                this.currentFieldInfo.dataType === FIELD_TYPES.STRING ||
                this.currentFieldInfo.dataType === FIELD_TYPES.TEXT ||
                this.currentFieldInfo.dataType === FIELD_TYPES.TEXTAREA ||
                this.currentFieldInfo.dataType === FIELD_TYPES.URL
            ) {
                picklistOperator.push({
                    value: 'Is Blank',
                    label: 'Is Blank'
                });
            }

            return picklistOperator;
        }

        return [];
    }

    checkOperatorType(type) {
        if (type && !this.currentOperator) {
            return false;
        }

        if (type === 'boolean') {
            if (
                (this.currentOperator === 'Is Null' || this.currentOperator === 'Is Blank') ||
                (
                    (this.currentOperator === 'Equals' || this.currentOperator === 'Does Not Equal') &&
                    (this.currentFieldInfo && this.currentFieldInfo.dataType === FIELD_TYPES.BOOLEAN)
                )
            ) {
                return true;
            }
        }
        if (type === 'picklist') {
            if (this.currentOperator === 'Equals' || this.currentOperator === 'Does Not Equal') {
                if (
                    this.currentFieldInfo &&
                    (this.currentFieldInfo.dataType === FIELD_TYPES.PICKLIST || this.currentFieldInfo.dataType === FIELD_TYPES.MULTI_PICKLIST)
                ) {
                    return true;
                }
            }
        }
        if (type === 'picklistContains') {
            if (this.currentOperator === 'Contains') {
                if (
                    this.currentFieldInfo &&
                    (this.currentFieldInfo.dataType === FIELD_TYPES.PICKLIST || this.currentFieldInfo.dataType === FIELD_TYPES.MULTI_PICKLIST)
                ) {
                    return true;
                }
            }
        }
        if (type === 'input') {
            if (
                this.currentOperator === 'Equals' ||
                this.currentOperator === 'Does Not Equal' ||
                this.currentOperator === 'Greater Than' ||
                this.currentOperator === 'Less Than'
            ) {
                if (!this.currentFieldInfo ||
                    (this.currentFieldInfo.dataType !== FIELD_TYPES.BOOLEAN && this.currentFieldInfo.dataType !== FIELD_TYPES.PICKLIST && this.currentFieldInfo.dataType !== FIELD_TYPES.MULTI_PICKLIST)
                ) {
                    return true;
                }
            }
        }
        return false;
    }

    get isBooleanOperator() {
        return this.checkOperatorType('boolean');
    }

    get isPicklistOperator() {
        return this.checkOperatorType('picklist');
    }

    get isInputOperator() {
        return this.checkOperatorType('input');
    }

    get isContainsPicklistOperator() {
        return this.checkOperatorType('picklistContains');
    }

    get isDefaultOperator() {
        return !this.checkOperatorType('boolean') && !this.checkOperatorType('picklist') && !this.checkOperatorType('input') && !this.checkOperatorType('picklistContains');
    }


    get getItemField() {
        if (this.item.Field_Name__c) {
            return this.item.Field_Name__c;
        }
        return '';
    }

    get getItemOperator() {
        if (this.item.Operator__c) {
            return this.item.Operator__c;
        }
        return '';
    }

    get getItemCondition() {
        if (this.isContainsPicklistOperator) {
            // Get condition value of contains picklist
            return this.item.Condition__c ? this.item.Condition__c.split(',') : [];
        } else {
            if (this.item.Condition__c) {
                return this.item.Condition__c;
            }
        }
        return '';
    }

    get getInputFieldType() {
        if (this.currentFieldInfo) {
            return this.currentFieldInfo.dataType;
        }
        return 'text';
    }

    get isAndAction() {
        return this.actionType === 'And' && this.itemIndex > 0;
    }

    get isOrAction() {
        return this.actionType === 'Or' && this.itemIndex > 0;
    }

    get isCustomAction() {
        return this.actionType === 'Custom';
    }

    getAllInputFields() {
        return [...this.template.querySelectorAll('lightning-combobox,lightning-input,lightning-dual-listbox')];
    }

    @api
    checkValidity() {
        let isValid = this.getAllInputFields().reduce((validSoFar, inputCmp) => {
            try {
                inputCmp.showHelpMessageIfInvalid();
            } catch (e) {
                // eslint-disable-next-line no-console
                console.error(e);
            }
            return validSoFar && inputCmp.checkValidity();
        });

        return isValid;
    }

    @api
    getRule() {
        let conditionValue = '';
        if (this.isContainsPicklistOperator) {
            conditionValue = this.currentConditionValue ? this.currentConditionValue.join(',') : this.item.Condition__c;
        } else {
            conditionValue = this.currentConditionValue ? this.currentConditionValue : this.item.Condition__c;
        }

        return {
            Sort_Order__c: this.item.Sort_Order__c,
            Field_Name__c: this.currentFieldInfo ? this.currentFieldInfo.apiName : this.item.Field_Name__c,
            Operator__c: this.currentOperator ? this.currentOperator : this.item.Operator__c,
            Condition__c: conditionValue
        };
    }
}