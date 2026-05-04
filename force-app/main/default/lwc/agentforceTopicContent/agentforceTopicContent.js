import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import SUBJECT_FIELD from '@salesforce/schema/Agentforce_Topic__c.Subject__c';
import CONTENT_FIELD from '@salesforce/schema/Agentforce_Topic__c.Content__c';

const FIELDS = [SUBJECT_FIELD, CONTENT_FIELD];

export default class AgentforceTopicContent extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    record;

    get subject() {
        return getFieldValue(this.record.data, SUBJECT_FIELD);
    }

    get content() {
        return getFieldValue(this.record.data, CONTENT_FIELD);
    }
}
