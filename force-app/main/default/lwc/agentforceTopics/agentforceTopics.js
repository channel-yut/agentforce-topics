import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getLatestTopic from '@salesforce/apex/AgentforceTopicsController.getLatestTopic';
import getTopicHistory from '@salesforce/apex/AgentforceTopicsController.getTopicHistory';
import updateFeedback from '@salesforce/apex/AgentforceTopicsController.updateFeedback';

// Import Custom Labels
import LABEL_TITLE from '@salesforce/label/c.AgentforceTopics_Title';
import LABEL_SUBTITLE_LATEST from '@salesforce/label/c.AgentforceTopics_SubtitleLatest';
import LABEL_TITLE_HISTORY from '@salesforce/label/c.AgentforceTopics_TitleHistory';
import LABEL_SUBTITLE_HISTORY from '@salesforce/label/c.AgentforceTopics_SubtitleHistory';
import LABEL_TITLE_HISTORY_DETAIL from '@salesforce/label/c.AgentforceTopics_TitleHistoryDetail';
import LABEL_SUBTITLE_ARCHIVE from '@salesforce/label/c.AgentforceTopics_SubtitleArchive';
import LABEL_BTN_SHOW_HISTORY from '@salesforce/label/c.AgentforceTopics_BtnShowHistory';
import LABEL_BTN_BACK_TO_LATEST from '@salesforce/label/c.AgentforceTopics_BtnBackToLatest';
import LABEL_BTN_BACK_TO_LIST from '@salesforce/label/c.AgentforceTopics_BtnBackToList';
import LABEL_BTN_VIEW from '@salesforce/label/c.AgentforceTopics_BtnView';
import LABEL_HISTORY_BANNER from '@salesforce/label/c.AgentforceTopics_HistoryBanner';
import LABEL_LOADING from '@salesforce/label/c.AgentforceTopics_Loading';
import LABEL_FEEDBACK_QUESTION from '@salesforce/label/c.AgentforceTopics_FeedbackQuestion';
import LABEL_FEEDBACK_HELPFUL from '@salesforce/label/c.AgentforceTopics_FeedbackHelpful';
import LABEL_FEEDBACK_NOT_HELPFUL from '@salesforce/label/c.AgentforceTopics_FeedbackNotHelpful';
import LABEL_FEEDBACK_SUCCESS from '@salesforce/label/c.AgentforceTopics_FeedbackSuccess';
import LABEL_FEEDBACK_SUCCESS_MSG from '@salesforce/label/c.AgentforceTopics_FeedbackSuccessMsg';
import LABEL_FEEDBACK_ERROR from '@salesforce/label/c.AgentforceTopics_FeedbackError';
import LABEL_SHARE_SLACK from '@salesforce/label/c.AgentforceTopics_ShareSlack';
import LABEL_COPY_TO_CLIPBOARD from '@salesforce/label/c.AgentforceTopics_CopyToClipboard';
import LABEL_NOT_IMPLEMENTED from '@salesforce/label/c.AgentforceTopics_NotImplemented';
import LABEL_SLACK_COMING_SOON from '@salesforce/label/c.AgentforceTopics_SlackComingSoon';
import LABEL_COPY_SUCCESS from '@salesforce/label/c.AgentforceTopics_CopySuccess';
import LABEL_COPY_SUCCESS_MSG from '@salesforce/label/c.AgentforceTopics_CopySuccessMsg';
import LABEL_COPY_ERROR from '@salesforce/label/c.AgentforceTopics_CopyError';
import LABEL_COL_DATE from '@salesforce/label/c.AgentforceTopics_ColDate';
import LABEL_COL_TRIGGER from '@salesforce/label/c.AgentforceTopics_ColTrigger';
import LABEL_COL_SUMMARY from '@salesforce/label/c.AgentforceTopics_ColSummary';
import LABEL_COL_ACTION from '@salesforce/label/c.AgentforceTopics_ColAction';
import LABEL_NO_DATA from '@salesforce/label/c.AgentforceTopics_NoData';
import LABEL_NO_DATA_MSG from '@salesforce/label/c.AgentforceTopics_NoDataMsg';
import LABEL_NO_HISTORY from '@salesforce/label/c.AgentforceTopics_NoHistory';
import LABEL_NO_HISTORY_MSG from '@salesforce/label/c.AgentforceTopics_NoHistoryMsg';
import LABEL_ERROR from '@salesforce/label/c.AgentforceTopics_Error';

export default class AgentforceTopics extends LightningElement {
    @api recordId; // Record ID from the record page context
    @api defaultCollapsed = false; // Property to control initial collapsed state
    @track currentMode = 'latest'; // 'latest', 'history-list', 'history-detail'
    @track currentTopic;
    @track historyTopics = [];
    @track selectedTopicId;
    @track isLoading = false;
    @track error;
    @track isCollapsed = false;

    wiredLatestResult;
    wiredHistoryResult;

    // Expose labels to template
    labels = {
        title: LABEL_TITLE,
        subtitleLatest: LABEL_SUBTITLE_LATEST,
        titleHistory: LABEL_TITLE_HISTORY,
        subtitleHistory: LABEL_SUBTITLE_HISTORY,
        titleHistoryDetail: LABEL_TITLE_HISTORY_DETAIL,
        subtitleArchive: LABEL_SUBTITLE_ARCHIVE,
        btnShowHistory: LABEL_BTN_SHOW_HISTORY,
        btnBackToLatest: LABEL_BTN_BACK_TO_LATEST,
        btnBackToList: LABEL_BTN_BACK_TO_LIST,
        btnView: LABEL_BTN_VIEW,
        historyBanner: LABEL_HISTORY_BANNER,
        loading: LABEL_LOADING,
        feedbackQuestion: LABEL_FEEDBACK_QUESTION,
        feedbackHelpful: LABEL_FEEDBACK_HELPFUL,
        feedbackNotHelpful: LABEL_FEEDBACK_NOT_HELPFUL,
        shareSlack: LABEL_SHARE_SLACK,
        copyToClipboard: LABEL_COPY_TO_CLIPBOARD,
        colDate: LABEL_COL_DATE,
        colTrigger: LABEL_COL_TRIGGER,
        colSummary: LABEL_COL_SUMMARY,
        colAction: LABEL_COL_ACTION,
        noData: LABEL_NO_DATA,
        noDataMsg: LABEL_NO_DATA_MSG,
        noHistory: LABEL_NO_HISTORY,
        noHistoryMsg: LABEL_NO_HISTORY_MSG
    };

    // Wire latest topic
    @wire(getLatestTopic, { recordId: '$recordId' })
    wiredLatest(result) {
        this.wiredLatestResult = result;
        if (result.data) {
            if (this.currentMode === 'latest') {
                this.currentTopic = result.data;
            }
            this.error = undefined;
            // Set initial collapsed state: use defaultCollapsed property if data exists
            this.isCollapsed = this.defaultCollapsed;
        } else if (result.error) {
            this.error = result.error;
            this.currentTopic = undefined;
            // Collapse when no data
            this.isCollapsed = true;
        } else if (!result.data) {
            // No data case
            this.currentTopic = undefined;
            this.isCollapsed = true;
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
        if (this.currentMode === 'latest') return LABEL_TITLE;
        if (this.currentMode === 'history-list') return LABEL_TITLE_HISTORY;
        return LABEL_TITLE_HISTORY_DETAIL;
    }

    get headerSubtitle() {
        if (this.currentMode === 'latest') return LABEL_SUBTITLE_LATEST;
        if (this.currentMode === 'history-list') return LABEL_SUBTITLE_HISTORY;
        if (this.currentTopic) {
            return `${LABEL_SUBTITLE_ARCHIVE} ${this.formatDateTime(this.currentTopic.Generated_Date__c)}`;
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
        return this.currentTopic?.Feedback__c === LABEL_FEEDBACK_HELPFUL
            ? 'slds-m-left_xx-small feedback-active'
            : 'slds-m-left_xx-small';
    }

    get thumbsDownClass() {
        return this.currentTopic?.Feedback__c === LABEL_FEEDBACK_NOT_HELPFUL
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

    // Filter out current topic from history list
    get filteredHistoryTopics() {
        if (!this.historyTopics || this.historyTopics.length === 0) return [];

        // Get current topic ID (from latest or selected history)
        const currentId = this.currentTopic?.Id;

        // Filter out the current topic
        return this.historyTopics.filter(topic => topic.Id !== currentId);
    }

    get hasHistory() {
        return this.filteredHistoryTopics && this.filteredHistoryTopics.length > 0;
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
        await this.submitFeedback(LABEL_FEEDBACK_HELPFUL);
    }

    async handleThumbsDown() {
        await this.submitFeedback(LABEL_FEEDBACK_NOT_HELPFUL);
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

            this.showToast(LABEL_FEEDBACK_SUCCESS, LABEL_FEEDBACK_SUCCESS_MSG, 'success');
        } catch (error) {
            this.showToast(LABEL_ERROR, LABEL_FEEDBACK_ERROR, 'error');
            console.error('Feedback error:', error);
        }
    }

    // Action handlers
    handleShareSlack() {
        // Placeholder for Slack integration
        this.showToast(LABEL_NOT_IMPLEMENTED, LABEL_SLACK_COMING_SOON, 'info');
    }

    handleCopyToClipboard() {
        if (!this.currentTopic?.Content__c) return;

        // Strip HTML tags for plain text copy
        const tempDiv = document.createElement('div');
        tempDiv.innerHTML = this.currentTopic.Content__c;
        const textContent = tempDiv.textContent || tempDiv.innerText || '';

        navigator.clipboard.writeText(textContent).then(() => {
            this.showToast(LABEL_COPY_SUCCESS, LABEL_COPY_SUCCESS_MSG, 'success');
        }).catch(err => {
            this.showToast(LABEL_ERROR, LABEL_COPY_ERROR, 'error');
            console.error('Copy error:', err);
        });
    }

    // Toggle collapse
    handleToggleCollapse() {
        this.isCollapsed = !this.isCollapsed;
    }

    get collapseIconName() {
        return this.isCollapsed ? 'utility:chevrondown' : 'utility:chevronup';
    }

    // Utility: Show toast
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
