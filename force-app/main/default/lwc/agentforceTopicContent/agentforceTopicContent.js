import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import SUBJECT_FIELD from '@salesforce/schema/Agentforce_Topic__c.Subject__c';
import CONTENT_FIELD from '@salesforce/schema/Agentforce_Topic__c.Content__c';
import TRIGGER_TYPE_FIELD from '@salesforce/schema/Agentforce_Topic__c.Trigger_Type__c';
import GENERATED_DATE_FIELD from '@salesforce/schema/Agentforce_Topic__c.Generated_Date__c';
import RELATED_LINKS_FIELD from '@salesforce/schema/Agentforce_Topic__c.Related_Links__c';

const FIELDS = [SUBJECT_FIELD, CONTENT_FIELD, TRIGGER_TYPE_FIELD, GENERATED_DATE_FIELD, RELATED_LINKS_FIELD];

export default class AgentforceTopicContent extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    record;

    get topic() {
        if (!this.record.data) return null;
        return {
            Subject__c: getFieldValue(this.record.data, SUBJECT_FIELD),
            Content__c: getFieldValue(this.record.data, CONTENT_FIELD),
            Trigger_Type__c: getFieldValue(this.record.data, TRIGGER_TYPE_FIELD),
            Generated_Date__c: getFieldValue(this.record.data, GENERATED_DATE_FIELD),
            Related_Links__c: getFieldValue(this.record.data, RELATED_LINKS_FIELD)
        };
    }
}
