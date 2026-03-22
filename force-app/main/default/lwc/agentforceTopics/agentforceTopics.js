import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getLatestTopic from '@salesforce/apex/AgentforceTopicsController.getLatestTopic';
import getTopicHistory from '@salesforce/apex/AgentforceTopicsController.getTopicHistory';
import updateFeedback from '@salesforce/apex/AgentforceTopicsController.updateFeedback';

export default class AgentforceTopics extends LightningElement {
    @api recordId; // Record ID from the record page context
    @track currentMode = 'latest'; // 'latest', 'history-list', 'history-detail'
    @track currentTopic;
    @track historyTopics = [];
    @track selectedTopicId;
    @track isLoading = false;
    @track error;

    wiredLatestResult;
    wiredHistoryResult;

    // Wire latest topic
    @wire(getLatestTopic, { recordId: '$recordId' })
    wiredLatest(result) {
        this.wiredLatestResult = result;
        if (result.data) {
            if (this.currentMode === 'latest') {
                this.currentTopic = result.data;
            }
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.currentTopic = undefined;
        }
    }

    // Wire history topics
    @wire(getTopicHistory, { recordId: '$recordId' })
    wiredHistory(result) {
        this.wiredHistoryResult = result;
        if (result.data) {
            this.historyTopics = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.historyTopics = [];
        }
    }

    // Computed properties for view states
    get showLatestView() {
        return this.currentMode === 'latest';
    }

    get showHistoryList() {
        return this.currentMode === 'history-list';
    }

    get showHistoryDetail() {
        return this.currentMode === 'history-detail';
    }

    get showInsightView() {
        return this.currentMode === 'latest' || this.currentMode === 'history-detail';
    }

    get isHistoryDetail() {
        return this.currentMode === 'history-detail';
    }

    // Header dynamic content
    get headerTitle() {
        if (this.currentMode === 'latest') return 'Agentforce Topics';
        if (this.currentMode === 'history-list') return '分析履歴';
        return '履歴の詳細';
    }

    get headerSubtitle() {
        if (this.currentMode === 'latest') return '最新の生成されたインサイト';
        if (this.currentMode === 'history-list') return '過去のAgentforceトピック一覧';
        if (this.currentTopic) {
            return `アーカイブ: ${this.formatDateTime(this.currentTopic.Generated_Date__c)}`;
        }
        return '';
    }

    get headerIconClass() {
        return this.isHistoryDetail
            ? 'ai-header-icon history-mode'
            : 'ai-header-icon';
    }

    // Feedback button states
    get thumbsUpClass() {
        return this.currentTopic?.Feedback__c === '役立った'
            ? 'slds-m-left_xx-small feedback-active'
            : 'slds-m-left_xx-small';
    }

    get thumbsDownClass() {
        return this.currentTopic?.Feedback__c === '役立たなかった'
            ? 'slds-m-left_xx-small feedback-active'
            : 'slds-m-left_xx-small';
    }

    // Date formatting
    get formattedDate() {
        return this.currentTopic?.Generated_Date__c
            ? this.formatDateTime(this.currentTopic.Generated_Date__c)
            : '';
    }

    formatDateTime(dateTime) {
        if (!dateTime) return '';
        const date = new Date(dateTime);
        return date.toLocaleString('ja-JP', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        }).replace(/\//g, '/');
    }

    get hasHistory() {
        return this.historyTopics && this.historyTopics.length > 0;
    }

    // Navigation handlers
    handleShowHistory() {
        this.currentMode = 'history-list';
    }

    handleShowLatest() {
        this.currentMode = 'latest';
        // Reload latest topic
        if (this.wiredLatestResult.data) {
            this.currentTopic = this.wiredLatestResult.data;
        }
    }

    handleShowHistoryList() {
        this.currentMode = 'history-list';
    }

    handleViewDetail(event) {
        const topicId = event.target.dataset.id;
        const selectedTopic = this.historyTopics.find(t => t.Id === topicId);
        if (selectedTopic) {
            this.currentTopic = selectedTopic;
            this.currentMode = 'history-detail';
        }
    }

    // Feedback handlers
    async handleThumbsUp() {
        await this.submitFeedback('役立った');
    }

    async handleThumbsDown() {
        await this.submitFeedback('役立たなかった');
    }

    async submitFeedback(feedbackValue) {
        if (!this.currentTopic?.Id) return;

        try {
            await updateFeedback({
                topicId: this.currentTopic.Id,
                feedback: feedbackValue
            });

            // Update local state
            this.currentTopic = { ...this.currentTopic, Feedback__c: feedbackValue };

            // Refresh wired data
            await Promise.all([
                refreshApex(this.wiredLatestResult),
                refreshApex(this.wiredHistoryResult)
            ]);

            this.showToast('フィードバック送信完了', 'ありがとうございました。', 'success');
        } catch (error) {
            this.showToast('エラー', 'フィードバックの送信に失敗しました。', 'error');
            console.error('Feedback error:', error);
        }
    }

    // Action handlers
    handleShareSlack() {
        // Placeholder for Slack integration
        this.showToast('未実装', 'Slack共有機能は今後実装予定です。', 'info');
    }

    handleCopyToClipboard() {
        if (!this.currentTopic?.Content__c) return;

        // Strip HTML tags for plain text copy
        const tempDiv = document.createElement('div');
        tempDiv.innerHTML = this.currentTopic.Content__c;
        const textContent = tempDiv.textContent || tempDiv.innerText || '';

        navigator.clipboard.writeText(textContent).then(() => {
            this.showToast('コピー完了', 'クリップボードにコピーしました。', 'success');
        }).catch(err => {
            this.showToast('エラー', 'コピーに失敗しました。', 'error');
            console.error('Copy error:', err);
        });
    }

    // Utility: Show toast
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
