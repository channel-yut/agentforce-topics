import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import SUMMARY_FIELD from '@salesforce/schema/Agentforce_Topic__c.Summary__c';
import CONTENT_FIELD from '@salesforce/schema/Agentforce_Topic__c.Content__c';

const FIELDS = [SUMMARY_FIELD, CONTENT_FIELD];

export default class AgentforceTopicContent extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    record;

    get summary() {
        return getFieldValue(this.record.data, SUMMARY_FIELD);
    }

    get content() {
        return getFieldValue(this.record.data, CONTENT_FIELD);
    }
}
