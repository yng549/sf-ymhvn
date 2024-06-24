import {
  FieldTypes,
  SupportedFieldTypes
} from './constants';

export const FIELD_TYPES = FieldTypes;
export const SUPPORTED_FIELD_TYPES = SupportedFieldTypes;
export const UNSUPPORTED_REFERENCE_FIELDS = [
  'OwnerId',
  'CreatedById',
  'LastModifiedById'
];

export function isCompoundField(field, objectInfo, personAccount = false) {
  const fieldInfo = objectInfo.fields[field];
  if (!fieldInfo) {
    return false;
  }

  if (fieldInfo.compound === false) {
    return false;
  }

  const keys = Object.keys(objectInfo.fields);
  for (let i = 0; i < keys.length; i++) {
    if (
      keys[i] !== field &&
      objectInfo.fields[keys[i]].compoundFieldName === field
    ) {
      if (
        objectInfo.apiName === 'Account' &&
        objectInfo.fields[keys[i]].compoundFieldName === 'Name' &&
        !personAccount
      ) {
        return false;
      }

      return true;
    }
  }

  return false;
}

export function getFieldInfo(field, objectInfo) {
  const fieldInfo = objectInfo.fields[field];
  if (!fieldInfo) {
    return false;
  }

  return fieldInfo;
}

export function getDataFieldWithNamespace(namespacePrefix, fieldName, recordData) {
  return namespacePrefix ? recordData[`${namespacePrefix}__${fieldName}`] : recordData[fieldName];
}

export function removeNamespacePrefixFromData(namespacePrefix, recordData) {
  if (!recordData || !namespacePrefix) {
    return recordData;
  }

  let clonedRecordData = {};
  for (let key of Object.keys(recordData)) {
    clonedRecordData[key.replace(namespacePrefix + '__', '')] = recordData[key];
  }

  return clonedRecordData;
}