import { LightningElement, api, track } from 'lwc';
import getRelatedRecordsInfo from '@salesforce/apex/AgentforceTopicsController.getRelatedRecordsInfo';

export default class AgentforceTopicInsight extends LightningElement {
    @api topic;
    @track relatedRecords = [];
    @track isLoadingLinks = false;

    _loadedRelatedLinksJson;

    connectedCallback() {
        this._loadRelatedRecords();
    }

    renderedCallback() {
        const json = this.topic?.Related_Links__c;
        if (json !== this._loadedRelatedLinksJson) {
            this._loadRelatedRecords();
        }
    }

    get formattedDate() {
        if (!this.topic?.Generated_Date__c) return '';
        const date = new Date(this.topic.Generated_Date__c);
        return date.toLocaleString('ja-JP', {
            year: 'numeric', month: '2-digit', day: '2-digit',
            hour: '2-digit', minute: '2-digit'
        });
    }

    get hasRelatedLinks() {
        return this.relatedRecords.length > 0 || this.isLoadingLinks;
    }

    async _loadRelatedRecords() {
        const json = this.topic?.Related_Links__c;
        this._loadedRelatedLinksJson = json;
        this.relatedRecords = [];
        if (!json) return;

        let ids;
        try {
            ids = JSON.parse(json);
        } catch (e) {
            return;
        }
        if (!Array.isArray(ids) || ids.length === 0) return;

        this.isLoadingLinks = true;
        try {
            const infos = await getRelatedRecordsInfo({ recordIds: ids });
            this.relatedRecords = infos.map(info => ({
                ...info,
                url: `/lightning/r/${info.recordId}/view`
            }));
        } catch (e) {
            this.relatedRecords = ids.map(id => ({
                recordId: id,
                label: id,
                iconName: 'standard:record',
                url: `/lightning/r/${id}/view`
            }));
        } finally {
            this.isLoadingLinks = false;
        }
    }
}
