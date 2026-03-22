import { LightningElement, api, wire } from 'lwc';
import getFeedbackStatistics from '@salesforce/apex/AgentforceTopicsController.getFeedbackStatistics';

// Import Custom Labels
import LABEL_STATS_TITLE from '@salesforce/label/c.AgentforceTopics_StatsTitle';
import LABEL_STATS_HELPFUL from '@salesforce/label/c.AgentforceTopics_StatsHelpful';
import LABEL_STATS_NOT_HELPFUL from '@salesforce/label/c.AgentforceTopics_StatsNotHelpful';
import LABEL_STATS_TOTAL_FEEDBACK from '@salesforce/label/c.AgentforceTopics_StatsTotalFeedback';
import LABEL_STATS_FEEDBACK_RATE from '@salesforce/label/c.AgentforceTopics_StatsFeedbackRate';
import LABEL_STATS_TOTAL_TOPICS from '@salesforce/label/c.AgentforceTopics_StatsTotalTopics';
import LABEL_STATS_NO_DATA from '@salesforce/label/c.AgentforceTopics_StatsNoData';

export default class AgentforceTopicsStats extends LightningElement {
    @api recordId;

    statistics;
    error;

    labels = {
        title: LABEL_STATS_TITLE,
        helpful: LABEL_STATS_HELPFUL,
        notHelpful: LABEL_STATS_NOT_HELPFUL,
        totalFeedback: LABEL_STATS_TOTAL_FEEDBACK,
        feedbackRate: LABEL_STATS_FEEDBACK_RATE,
        totalTopics: LABEL_STATS_TOTAL_TOPICS,
        noData: LABEL_STATS_NO_DATA
    };

    @wire(getFeedbackStatistics, { recordId: '$recordId' })
    wiredStatistics({ data, error }) {
        if (data) {
            this.statistics = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.statistics = undefined;
        }
    }

    get hasData() {
        return this.statistics && this.statistics.totalTopicsCount > 0;
    }

    get formattedFeedbackRate() {
        if (!this.statistics || !this.statistics.feedbackRate) {
            return '0%';
        }
        return `${(this.statistics.feedbackRate * 100).toFixed(1)}%`;
    }

    get helpfulPercentage() {
        if (!this.statistics || this.statistics.totalFeedbackCount === 0) {
            return 0;
        }
        return (this.statistics.helpfulCount / this.statistics.totalFeedbackCount) * 100;
    }

    get notHelpfulPercentage() {
        if (!this.statistics || this.statistics.totalFeedbackCount === 0) {
            return 0;
        }
        return (this.statistics.notHelpfulCount / this.statistics.totalFeedbackCount) * 100;
    }

    get helpfulProgressClass() {
        const percentage = this.helpfulPercentage;
        if (percentage >= 80) return 'slds-progress-bar__value progress-success';
        if (percentage >= 50) return 'slds-progress-bar__value progress-warning';
        return 'slds-progress-bar__value progress-error';
    }

    get helpfulProgressStyle() {
        return `width: ${this.helpfulPercentage}%`;
    }

    get notHelpfulProgressStyle() {
        return `width: ${this.notHelpfulPercentage}%`;
    }
}
